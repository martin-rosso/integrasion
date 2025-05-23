module Nexo
  class FolderSyncJob < BaseJob
    def perform(folder)
      protocol_service = ServiceBuilder.instance.build_protocol_service(folder)
      if folder.external_identifier.blank?
        response = protocol_service.insert_calendar(folder)
        folder.update(external_identifier: response.id)
      else
        protocol_service.update_calendar(folder)
      end

      policies = PolicyService.instance.policies_for(folder)
      # flat_map should be equivalent to:
      #   policies.map(&:synchronizable_queries).flatten(1)
      queries = policies.flat_map(&:synchronizable_queries)

      GoodJob::Bulk.enqueue do
        queries.each do |query|
          # TODO: avoid calling more than once per synchronizable
          query.find_each do |synchronizable|
            folder_service.find_element_and_sync(folder, synchronizable)
          end
        end
      end
    end

    private

    # :nocov: mocked
    def folder_service
      @folder_service ||= FolderService.new
    end
    # :nocov:
  end
end
