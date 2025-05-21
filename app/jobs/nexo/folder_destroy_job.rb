module Nexo
  class FolderDestroyJob < BaseJob
    def perform(folder)
      if folder.external_identifier.present?
        protocol_service = ServiceBuilder.instance.build_protocol_service(folder)
        response = protocol_service.remove_calendar(folder)
      end
    end
  end
end
