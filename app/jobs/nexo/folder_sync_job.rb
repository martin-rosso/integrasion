module Nexo
  class FolderSyncJob < BaseJob
    def perform(folder)
      policies = PolicyService.instance.policies_for(folder)
      # flat_map should be equivalent to:
      #   policies.map(&:synchronizable_queries).flatten(1)
      queries = policies.flat_map(&:synchronizable_queries)

      queries.each do |query|
        # TODO: avoid calling more than once per synchronizable
        query.find_each do |synchronizable|
          folder_service.find_element_and_sync(folder, synchronizable)
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
