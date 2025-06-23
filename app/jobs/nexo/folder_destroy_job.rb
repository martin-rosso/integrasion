module Nexo
  class FolderDestroyJob < BaseJob
    # TODO!: limit concurrency
    def perform(folder)
      if folder.external_identifier.present?
        protocol_service = ServiceBuilder.instance.build_protocol_service(folder)
        response = protocol_service.remove_calendar(folder)
      else
        Nexo.logger.info("Folder doesn't have external_identifier: #{folder.to_gid}")
      end
    end
  end
end
