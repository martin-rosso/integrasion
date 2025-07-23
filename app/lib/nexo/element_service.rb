module Nexo
  class ElementService
    attr_accessor :element, :element_version

    def initialize(element_version: nil, element: nil)
      @element_version = element_version
      @element = element || element_version&.element
    end

    def create_element_version!(attributes)
      element.with_lock do
        _create_element_version!(attributes)
      end
    end

    def update_element_version!(attributes)
      element.with_lock do
        element_version.update!(attributes)
        _update_ne_status!
      end
    end

    def update_element!(attributes)
      element.update!(attributes)
    end

    def discard!
      element.update!(discarded_at: Time.current)
      _update_ne_status!
    end

    # The reason of `flagged_for_removal` is that there is a time gap between
    # the the user action of removing the element and the actual API call that
    # deletes the remote element. At some point is necesary to know if the
    # element is being deleted, like when fetching a remote version previous to
    # the actual delete API call.
    def flag_for_removal!(removal_reason)
      Nexo.logger.debug("Flagging an element for removal")

      element.update!(flagged_for_removal: true, removal_reason:)
      _update_ne_status!
    end

    # @raise Nexo::Errors::UpdateToSynchronizableFailed
    def update_synchronizable!
      Nexo.logger.debug("update_synchronizable!")

      element.with_lock do
        service = ServiceBuilder.instance.build_protocol_service(element_version.element.folder)
        fields = service.fields_from_payload(element_version.payload)

        # and set the Synchronizable fields according to the Folder#nexo_protocol
        synchronizable = element_version.element.synchronizable
        if element.flagged_for_removal?
          Nexo.logger.info("Element flagged for removal")
          ElementService.new(element_version:).update_element_version!(
            nev_status: :ignored_by_deletion
          )
        elsif synchronizable.present?
          begin
            synchronizable.update_from_fields!(fields)
          rescue ActiveRecord::ActiveRecordError => e
            raise Errors::UpdateToSynchronizableFailed, e.inspect
          end

          # synchronizable could have been destroyed
          if synchronizable.persisted?
            # si esto se ejecuta en paralelo con SynchronizableChangedJob? (para otro
            # element del mismo synchronizable) puede haber race conditions
            synchronizable.increment_sequence!
            synchronizable.reload

            ElementService.new(element_version:).update_element_version!(
              sequence: synchronizable.sequence,
              nev_status: :synced
            )

            SynchronizableChangedJob.perform_later(synchronizable, excluded_folders: [ element.folder.id ])
          else
            Nexo.logger.debug("Synchronizable destroyed. Removing other elements")
            ElementService.new(element_version:).update_element_version!(
              sequence: nil,
              nev_status: :synced
            )

            FolderService.new.destroy_elements(
              synchronizable, :synchronizable_destroyed, exclude_elements: [ element.id ])
          end
        else
          Nexo.logger.info("Synchronizable not found")
          policies = PolicyService.instance.policies_for(element.folder)
          importer_rule = policies.select { |p| p.import_payload?(element_version.payload) }.first
          if importer_rule.present?
            Nexo.logger.debug("Found an importer rule")
            synchronizable = importer_rule.create_synchronizable_from_payload!(element_version.payload)
            ElementService.new(element:).update_element!(synchronizable:)
            ElementService.new(element_version:).update_element_version!(
              nev_status: :synced,
              sequence: synchronizable.sequence
            )
            SynchronizableChangedJob.perform_later(synchronizable, excluded_folders: [ element.folder.id ])
          else
            Nexo.logger.info("No importer rule found for event. Skipping")
          end
        end
      end
    end

    def resolve_conflict!
      Nexo.logger.debug("_resolve_conflict!")

      unless element.conflicted?
        raise "element not conflicted"
      end

      # both lock on Element and start a transaction
      element.with_lock do
        external_change = _last_pending_external_change
        local_change = _last_pending_internal_change

        # NOTE: before doing any conflict solving, a supersed check should be
        # done, i.e.: some of the versions in conflict could be actually
        # superseded, and should be marked accordingly

        remote_update = external_change.payload_updated_at

        # TODO: should check the version's updated_at?
        local_update = element.synchronizable.updated_at
        Nexo.logger.debug { "Remote updated at: #{remote_update}. Local updated at #{local_update}" }
        if remote_update > local_update
          Nexo.logger.debug("Remote wins")
          _update_status_on_conflict_with_winner!(external_change)
        else
          Nexo.logger.debug("Local wins")
          _update_status_on_conflict_with_winner!(local_change)
        end
      end
    end

    def _perform_sync!
      external_change = _last_pending_external_change
      local_change = _last_pending_internal_change

      if element.pending_local_sync?
        Nexo.logger.info("_perform_sync!: Local change: enqueuing UpdateRemoteResourceJob")
        UpdateRemoteResourceJob.perform_later(local_change)
      elsif element.pending_external_sync?
        Nexo.logger.info("_perform_sync!: External change: running ImportRemoteElementVersion")
        ImportRemoteElementVersion.new.perform(external_change)
      else
        Nexo.logger.info("Element's ne_status is: #{element.ne_status}. Nothing to do")
      end
    end

    def _last_pending_external_change
      element.element_versions.where(origin: :external, nev_status: :pending_sync).order(:etag).last
    end

    def _last_pending_internal_change
      element.element_versions.where(origin: :internal, nev_status: :pending_sync).order(:sequence).last
    end

    def _last_synced_version
      element.element_versions.where(nev_status: :synced).order(:sequence).last
    end

    def update_ne_status!
      element.with_lock do
        _update_ne_status!
      end
    end

    def create_internal_version_if_none!
      # NOTE: though synchronizable it's not locked and could change in between
      # the block, this shouldn't run concurrently because its called from
      # SynchronizableChangedJob that its limited to one perform at a time per
      # synchronizable
      element.with_lock do
        if element.element_versions.where(sequence: element.synchronizable.sequence).any?
          Nexo.logger.debug { "There is a version for current sequence, nothing to do" }
          return
        end

        _create_internal_version!
      end
    end

    def create_element_for_remote_resource!(folder, response)
      Element.create!(
        folder:,
        uuid: response.id,
        ne_status: :pending_external_sync
      )
    end

    def create_element_for!(folder, synchronizable)
      Element.transaction do
        @element = Element.create!(
          synchronizable:,
          folder:,
          ne_status: :pending_local_sync
        )
        Nexo.logger.debug { "Element created" }

        _create_internal_version!
      end
    end

    private

    def _update_status_on_conflict_with_winner!(win_version)
      element.element_versions.where(nev_status: :pending_sync)
        .where.not(id: win_version.id)
        .update_all(nev_status: :ignored_in_conflict)

      _update_ne_status!
    end

    def _create_internal_version!
      nev_status =
        element.folder.sync_internal_changes? ? :pending_sync : :ignored_by_sync_direction

      _create_element_version!(
        origin: :internal,
        sequence: element.synchronizable.sequence,
        nev_status:
      )
    end

    def _create_element_version!(attributes)
      ElementVersion.create!(attributes.merge(element:)).tap do
        Nexo.logger.debug("ElementVersion created")
        _update_ne_status!

        if element.conflicted?
          resolve_conflict!
        end

        begin
          _perform_sync!
        rescue Errors::UpdateToSynchronizableFailed => e
          # This shouldnt rollback the ElementVersion creation
          Nexo.logger.warn(e.inspect)
        end
      end
    end

    def _update_ne_status!
      external_change =
        element.folder.sync_external_changes? &&
          element.element_versions.where(origin: :external, nev_status: :pending_sync).any?

      local_change =
        element.folder.sync_internal_changes? &&
          element.element_versions.where(origin: :internal, nev_status: :pending_sync).any?

      last_remote = element.last_remote_version

      element.ne_status =
        if element.discarded?
          :discarded
        elsif external_change && local_change
          :conflicted
        elsif external_change
          :pending_external_sync
        elsif local_change
          :pending_local_sync
        elsif element.flagged_for_removal? && element.discarded_at.nil?
          # This probably indicates an error during remote deletion
          :pending_remote_delete
        elsif last_remote.present? && last_remote.nev_status != "synced"
          # This probably indicates a remote change that couldnt be imported
          # because of sync_direction
          :unsynced_remote_change
        else
          :synced
        end

      element.save!
    end
  end
end
