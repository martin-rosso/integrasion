module Nexo
  # - Removing/discarding Element's
  class DeleteRemoteResourceJob < BaseJob
    include ApiClients

    retry_on(Errors::ConflictingRemoteElementChange, attempts: 2)

    # Once discarded, an Element is obsolete and cant be restored because even
    # though some APIs may allow it, others may not.
    def perform(element)
      raise "element already discarded" if element.discarded?

      service = ServiceBuilder.instance.build_protocol_service(element.folder)
      service.remove(element)
      service_response = service.get_event(element)

      ElementService.new(element:).create_element_version!(
        origin: :internal,
        etag: service_response.etag,
        payload: service_response.payload,
        sequence: nil,
        nev_status: :synced
      )
      ElementService.new(element:).discard!
    rescue Errors::ConflictingRemoteElementChange => e
      Nexo.logger.warn <<~STR
        ConflictingRemoteElementChange for #{element.to_gid}. \

        Performing now FetchRemoteResourceJob, so next attempt should succeed
      STR

      # NOTE: maybe this should be performed always directly in the first attempt?
      FetchRemoteResourceJob.perform_now(element)

      raise e
    end
  end
end
