module Nexo
  # - Removing/discarding Element's
  class DeleteRemoteResourceJob < BaseJob
    include ApiClients

    def perform(element)
      if element.discarded?
        raise "element already discarded"
      end

      unless element.flagged_for_removal?
        raise "element not flagged for removal"
      end

      ServiceBuilder.instance.build_protocol_service(element.folder).remove(element)

      ElementService.new(element:).discard!
    end
  end
end
