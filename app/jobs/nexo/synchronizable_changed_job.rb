module Nexo
  class SynchronizableChangedJob < BaseJob
    limits_concurrency key: ->(synchronizable) { synchronizable.to_gid }

    # TODO: check
    # https://github.com/rails/solid_queue?tab=readme-ov-file#jobs-and-transactional-integrity
    #
    # TODO: handle exceptions

    def perform(synchronizable)
      # Maybe restrict this query to a more specific scope
      scope = Folder.all

      scope.each do |folder|
        folder_service.find_element_and_sync(folder, synchronizable)
      end
    end

    private

    def folder_service
      @folder_service ||= FolderService.new
    end
  end
end
