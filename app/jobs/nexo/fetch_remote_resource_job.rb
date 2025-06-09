module Nexo
  # Always must be executed asynchronously to ensure the concurrency limit applies
  #
  # Responsabilities:
  #   - Creating a ElementVersion on external incoming change
  #   - Updating a Synchronizable for that external change
  #
  # @raise ActiveRecord::RecordNotUnique
  class FetchRemoteResourceJob < BaseJob
    include ApiClients

    attr_reader :element
    attr_reader :element_version

    def perform(element)
      @element = element

      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      response = remote_service.get_event(element)
      # TODO!: handle calendar change

      if response.present? && element.element_versions.where(etag: response.etag).empty?
        Nexo.logger.debug { "Fetched new element version from remote server" }
        Nexo.logger.debug { response.payload }

        version = save_element_version(response)

        # set ne_status = pending_external_sync
        element.update_ne_status!

        ImportRemoteElementVersion.new.perform(version)
      else
        Nexo.logger.debug { "No new version fetched from remote server" }
      end
    end

    private

    def save_element_version(service_response)
      @element_version = ElementVersion.create!(
        element:,
        origin: :external,
        etag: service_response.etag,
        payload: service_response.payload,
        sequence: nil,
        nev_status: :pending_sync
      )
    end
  end
end
