module Nexo
  # Always must be executed asynchronously to ensure the concurrency limit applies
  #
  # Responsabilities:
  #   - Updating Synchronizable's on external incoming changes
  #
  # @raise ActiveRecord::RecordNotUnique
  class FetchRemoteResourceJob < BaseJob
    include ApiClients

    attr_reader :element

    def perform(element)
      @element = element

      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      response = remote_service.get_event(element)
      # TODO!: handle calendar change
      # FIXME: handle event not found

      if element.element_versions.where(etag: response.etag).empty?
        Nexo.logger.debug { "Fetched new element version from remote" }
        Nexo.logger.debug { response.payload }

        version = save_element_version(response)
        element.update_ne_status!

        ImportRemoteElementVersionJob.new.perform(version)
      else
        Nexo.logger.debug { "No new version fetched from remote" }
      end
    end

    private

    def save_element_version(service_response)
      ElementVersion.create!(
        element:,
        origin: :external,
        etag: service_response.etag,
        payload: service_response.payload,
        sequence: nil,
        nev_status: :pending_sync
      )
    end
  end

  class ImportRemoteElementVersionJob
    def perform(element_version)
      element = element_version.element

      validate_element_state!(element)

      element.synchronizable.update_from!(element_version)

      element.update_ne_status!
    end

    private

    def validate_element_state!(element)
      # FIXME: qué onda, esto, quizá ya no es necesario TAANTO
      if element.synchronizable.blank? && !element.flagged_for_removal?
        # element should have been flagged for removal
        raise Errors::SynchronizableNotFound, element
      end

      if element.discarded?
        # TODO: maybe check the case of external incoming changes to flag the element as conflicted
        raise Errors::ElementDiscarded, element
      end

      # redundant?
      element.update_ne_status!

      if element.conflicted?
        raise Errors::ElementConflicted, element
      end

      if element.synchronizable.present? && element.synchronizable.conflicted?
        raise Errors::SynchronizableConflicted, element
      end

      if element.synchronizable.present? && element.synchronizable.sequence.nil?
        raise Errors::SynchronizableSequenceIsNull, element
      end
    end
  end
end
