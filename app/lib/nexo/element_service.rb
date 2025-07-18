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
    end

    def flag_for_removal!(removal_reason)
      Nexo.logger.debug("Flagging an element for removal")

      # TODO!: the reason for this? just monitoring?
      element.update!(flagged_for_removal: true, removal_reason:)
    end

    # @raise ActiveRecord::RecordNotUnique
    def update_synchronizable!
      Nexo.logger.debug("update_synchronizable!")

      element.with_lock do
        service = ServiceBuilder.instance.build_protocol_service(element_version.element.folder)
        fields = service.fields_from_payload(element_version.payload)

        # and set the Synchronizable fields according to the Folder#nexo_protocol
        synchronizable = element_version.element.synchronizable
        if synchronizable.present?
          synchronizable.update_from_fields!(fields)

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
          else
            Nexo.logger.info("No importer rule found for event. Skipping")
          end
        end
      end
    end

    def resolve_conflict!
      unless element.conflicted?
        raise "element not conflicted"
      end

      # both lock on Element and start a transaction
      element.with_lock do
        external_change = element.element_versions.where(origin: :external, nev_status: :pending_sync).order(:etag).last
        local_change = element.element_versions.where(origin: :internal, nev_status: :pending_sync).order(:sequence).last
        last_synced = element.element_versions.where(nev_status: :synced).order(:sequence).last

        if local_change.sequence < last_synced.sequence
          raise "there a newer synced sequence"
        end

        if external_change.etag < last_synced.etag
          raise "there a newer synced etag"
        end

        Nexo.logger.debug { "resolving conflict" }
        remote_update = Time.zone.parse(external_change.payload["updated"])
        local_update = element.synchronizable.updated_at
        Nexo.logger.debug { "Remote updated at: #{remote_update}. Local updated at #{local_update}" }
        if remote_update > local_update
          Nexo.logger.debug { "Remote wins, ignoring local change" }
          _update_status_on_conflict_with_winner!(external_change)
          ImportRemoteElementVersion.new.perform(external_change)
        else
          Nexo.logger.debug { "Local wins, discarding remote changes" }
          _update_status_on_conflict_with_winner!(local_change)
          UpdateRemoteResourceJob.perform_later(local_change)
        end
      end
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
      ).tap do |element_version|
        Nexo.logger.debug("ElementVersion created")

        if element.pending_local_sync?
          Nexo.logger.debug("Enqueuing UpdateRemoteResourceJob")

          UpdateRemoteResourceJob.perform_later(element_version)
        elsif element.conflicted?
          Nexo.logger.info("Element conflicted, so not enqueuing UpdateRemoteResourceJob")
        elsif element.synced?
          Nexo.logger.info("Element's ne_status is: #{element.ne_status}. No need to push any changes.")
        else
          # :nocov: borderline
          Nexo.logger.info("Element's ne_status is: #{element.ne_status}. That's weird.")
          # :nocov:
        end
      end
    end

    def _create_element_version!(attributes)
      ElementVersion.create!(attributes.merge(element:)).tap do
        _update_ne_status!
      end
    end

    def _update_ne_status!
      external_change =
        element.folder.sync_external_changes? &&
          element.element_versions.where(origin: :external, nev_status: :pending_sync).any?

      local_change =
        element.folder.sync_internal_changes? &&
          element.element_versions.where(origin: :internal, nev_status: :pending_sync).any?

      element.ne_status =
        if external_change && local_change
          :conflicted
        elsif external_change
          :pending_external_sync
        elsif local_change
          :pending_local_sync
        else
          :synced
        end

      element.save!
    end
  end
end
