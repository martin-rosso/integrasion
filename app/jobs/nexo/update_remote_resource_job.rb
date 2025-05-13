module Nexo
  class UpdateRemoteResourceJob < BaseJob
    limits_concurrency key: ->(element) { element.gid }, group: "RemoteResources"
    # TODO: set polling interval 10 secs or so

    def perform(element)
      validate

      response =
        if element.element_versions.any?
          GoogleCalendar.update(element.synchronizable)
        else
          GoogleCalendar.insert(element.synchronizable)
        end

      save_element_version(element, response)
    end

    private

    def validate
      if element.synchronizable.conflicted?
        raise :conflict
      end

      if element.external_unsynced_change?
        raise :conflict
      end

      current_sequence = element.synchronizable.sequence
      last_synced_sequence = element.last_synced_sequence

      unless current_sequence > last_synced_sequence
        raise :nothing_to_do
      end
    end

    def save_element_version(element, service_response)
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
