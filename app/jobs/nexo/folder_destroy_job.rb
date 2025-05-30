module Nexo
  class FolderDestroyJob < BaseJob
    # FIXME: limit concurrency
    def perform(folder)
      if folder.external_identifier.present?
        protocol_service = ServiceBuilder.instance.build_protocol_service(folder)
        response = protocol_service.remove_calendar(folder)
      else
        Rails.logger.info("Folder doesn't have external_identifier: #{folder.to_gid}")
      end
    end
  end
end
