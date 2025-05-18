module Nexo
  class UpdateRemoteResourceJob < BaseJob
    # TODO: limit by integration, instead of element
    limits_concurrency key: ->(element) { element.gid }, group: "IntegrationApiCall"
    # TODO: set polling interval 10 secs or so

    attr_reader :element

    def perform(element)
      @element = element

      validate_element_state!

      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      response =
        if element.element_versions.any?
          remote_service.update(element)
        else
          remote_service.insert(element.folder, element)
        end

      save_element_version(response)
    end

    private

    def validate_element_state!
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
