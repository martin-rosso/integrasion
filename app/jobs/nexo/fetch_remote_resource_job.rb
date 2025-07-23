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

    def perform(element)
      @element = element

      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      response = remote_service.get_event(element)
      # TODO!: handle calendar change

      handle_response(element, response)
    end

    def handle_response(element, response)
      # TODO!: refactor y que no tenga que repetir esta asignación
      #        extraer a algún Service?
      @element = element
      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      if response.present?
        if remote_service.payload_readonly?(response.payload)
          Nexo.logger.debug("Remote element found but READONLY")
          ElementService.new(element:).update_element!(ne_remote_status: :found_readonly)
        else
          Nexo.logger.debug("Remote element found")
          ElementService.new(element:).update_element!(ne_remote_status: :found)
        end

        if version = element.element_versions.where(etag: response.etag).first
          # No need to run it through ElementService
          version.update(payload: response.payload)

          if version.saved_changes?
            Nexo.logger.debug("Known version, payload updated")
          else
            Nexo.logger.debug("Known version, untouched")
          end
        else
          Nexo.logger.debug("Fetched new element version from remote server")
          Nexo.logger.debug(response.payload)

          element_version = save_element_version(response)
        end
      else
        Nexo.logger.debug("Remote element missing")
        ElementService.new(element:).update_element!(ne_remote_status: :missing)
      end
    end

    private

    def save_element_version(service_response)
      nev_status =
        element.folder.sync_external_changes? ? :pending_sync : :ignored_by_sync_direction

      ElementService.new(element:).create_element_version!(
        origin: :external,
        etag: service_response.etag,
        payload: service_response.payload,
        sequence: nil,
        nev_status:
      )
    end
  end
end
