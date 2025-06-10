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
      # TODO!: the reason for this? just monitoring?
      element.update!(flagged_for_removal: true, removal_reason:)
    end

    # @raise ActiveRecord::RecordNotUnique
    def update_synchronizable!
      element.with_lock do
        service = ServiceBuilder.instance.build_protocol_service(element_version.element.folder)
        fields = service.fields_from_version(element_version)

        # and set the Synchronizable fields according to the Folder#nexo_protocol
        synchronizable = element_version.element.synchronizable
        synchronizable.assign_fields!(fields)

        # si esto se ejecuta en paralelo con SynchronizableChangedJob? (para otro
        # element del mismo synchronizable) puede haber race conditions
        synchronizable.increment_sequence!
        synchronizable.reload

        ElementService.new(element_version:).update_element_version!(
          sequence: synchronizable.sequence,
          nev_status: :synced
        )

        SynchronizableChangedJob.perform_later(synchronizable)
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
          ImportRemoteElementVersion.new.perform(external_change)
          win_version = external_change
        else
          Nexo.logger.debug { "Local wins, discarding remote changes" }
          UpdateRemoteResourceJob.perform_later(local_change)
          win_version = local_change
        end

        element.element_versions.where(nev_status: :pending_sync)
                        .where.not(id: win_version.id)
                        .update_all(nev_status: :ignored_in_conflict)

        _update_ne_status!
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

    def _create_internal_version!
      _create_element_version!(
        origin: :internal,
        sequence: element.synchronizable.sequence,
        nev_status: :pending_sync
      ).tap do |element_version|
        Nexo.logger.debug { "ElementVersion created" }

        if element.pending_local_sync?
          Nexo.logger.debug { "Enqueuing UpdateRemoteResourceJob" }

          UpdateRemoteResourceJob.perform_later(element_version)
        elsif element.conflicted?
          Nexo.logger.info { "Element conflicted, so not enqueuing UpdateRemoteResourceJob" }
        else
          # :nocov: borderline
          Nexo.logger.warn { "Element status is: #{element.ne_status}. That's weird" }
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
      external_change = element.element_versions.where(origin: :external, nev_status: :pending_sync).any?
      local_change = element.element_versions.where(origin: :internal, nev_status: :pending_sync).any?

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
