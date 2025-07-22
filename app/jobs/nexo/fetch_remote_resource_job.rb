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

      if response.present?
        Nexo.logger.debug("Remote element found")
        element.update(ne_remote_status: :found)

        if version = element.element_versions.where(etag: response.etag).first
          # Nexo.logger.debug { "No new version fetched from remote server" }
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

          # FIXME: if element conflicted, resolve instead
          #        what if conflict occurs when creating an internal version?
          if element.folder.sync_external_changes?
            ImportRemoteElementVersion.new.perform(element_version)
          else
            Nexo.logger.info("Element version ignored_by_sync_direction")
          end
        end
      else
        Nexo.logger.debug("Remote element missing")
        element.update(ne_remote_status: :missing)
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
