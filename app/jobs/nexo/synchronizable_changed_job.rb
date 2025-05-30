module Nexo
  class SynchronizableChangedJob < BaseJob
    # :nocov: tricky
    if defined? GoodJob
      include GoodJob::ActiveJobExtensions::Concurrency

      good_job_control_concurrency_with(
        perform_limit: 1,
        key: -> { arguments.first.to_gid.to_s }
      )
    end
    # :nocov:

    # TODO: check
    # https://github.com/rails/solid_queue?tab=readme-ov-file#jobs-and-transactional-integrity
    #
    # TODO: handle exceptions

    def perform(synchronizable)
      # Maybe restrict this query to a more specific scope
      scope = Folder.kept
      Nexo.logger.debug { "Processing #{scope.count} folders" }

      # TODO: test
      GoodJob::Bulk.enqueue do
        scope.each do |folder|
          folder_service.find_element_and_sync(folder, synchronizable)
        end
      end
    end

    private

    def folder_service
      @folder_service ||= FolderService.new
    end
  end
end
