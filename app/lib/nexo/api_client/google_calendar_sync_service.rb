module Nexo
  class GoogleCalendarSyncService < GoogleCalendarService
    def full_sync!(folder)
      Nexo.logger.info("performing full sync")
      sync!(folder)
    end

    def incremental_sync!(folder)
      raise Nexo::Errors::Error, "no sync token" if folder.google_next_sync_token.blank?

      Nexo.logger.debug("performing incremental sync")
      sync!(folder, sync_token: folder.google_next_sync_token)
    rescue Google::Apis::ClientError => e
      if e.message.match /fullSyncRequired/
        Nexo.logger.warn "Full sync required: #{e}"
        full_sync!(folder)
      else
        raise
      end
    end

    def full_or_incremental_sync!(folder)
      if folder.google_next_sync_token.present?
        incremental_sync!(folder)
      else
        full_sync!(folder)
      end
    end

    private

    # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
    #   TODO: handle 410 (Gone) to discard the sync_token and schedule a full_sync
    #    (fullSyncRequired: Sync token is no longer valid, a full sync is required.
    def sync!(folder, page_token: nil, sync_token: nil)
      page_token = nil
      loop do
        if page_token.present?
          Nexo.logger.debug("Calling list_events with page_token")
        elsif sync_token.present?
          Nexo.logger.debug("Calling list_events with sync_token")
          # raise Google::Apis::ClientError, "fullSyncRequired: Sync token is no longer valid..."
        else
          Nexo.logger.debug("Calling list_events without sync_token")
        end

        events = client.list_events(folder.external_identifier, page_token:, sync_token:)
        Nexo.logger.debug("retrieved a page with #{events.items.length} items")
        sync_token = nil

        events.items.each do |event|
          response = ApiResponse.new(payload: event.to_h, etag: event.etag, id: event.id)

          element = Element.where(uuid: response.id).first
          if element.present?
            Nexo.logger.debug("Element found for event")

            FetchRemoteResourceJob.new.handle_response(element, response)
          else
            element = ElementService.new.create_element_for_remote_resource!(folder, response)

            # FIXME: rename handle_response
            FetchRemoteResourceJob.new.handle_response(element, response)
          end
        end

        page_token = events.next_page_token
        if page_token
          Nexo.logger.debug("Page token present. Fetching next page.")
        else
          sync_token = events.next_sync_token
          if sync_token.present?
            Nexo.logger.debug("Sync token present. Saving it to Folder")
            folder.update!(google_next_sync_token: sync_token)
          else
            Nexo.logger.error("Sync token should have been present!")
          end

          break
        end
      end
    end
  end
end
