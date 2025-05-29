module Nexo
  class UpdateRemoteResourceJob < BaseJob
    include ApiClients

    attr_reader :element

    def perform(element)
      @element = element

      validate_element_state!

      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      response =
        if element.element_versions.any?
          remote_service.update(element)
        else
          remote_service.insert(element.folder, element.synchronizable).tap do |response|
            element.update(uuid: response.id)
          end
        end

      save_element_version(response)
    end

    private

    def validate_element_state!
      if element.synchronizable.blank?
        raise Errors::SynchronizableNotFound
      end

      if element.discarded?
        raise Errors::ElementDiscarded
      end

      if element.synchronizable.respond_to?(:discarded?) && element.synchronizable.discarded?
        raise Errors::SynchronizableDiscarded
      end

      if element.folder.discarded?
        raise Errors::FolderDiscarded
      end

      if element.synchronizable.conflicted?
        raise Errors::ElementConflicted
      end

      if element.external_unsynced_change?
        raise Errors::ExternalUnsyncedChange
      end

      current_sequence = element.synchronizable.sequence
      last_synced_sequence = element.last_synced_sequence

      unless current_sequence > last_synced_sequence
        raise Errors::ElementAlreadySynced
      end
    end

    # @todo sequence should be fetched before to avoid being outdated
    def save_element_version(service_response)
      ElementVersion.create!(
        element:,
        origin: :internal,
        etag: service_response.etag,
        payload: service_response.payload,
        sequence: element.synchronizable.sequence,
      )
    end
  end
end
