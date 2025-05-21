module Nexo
  # This callbacks must be called when synchronizables change locally, must not
  # be called when the system is notified of an external element change
  class EventReceiver
    def synchronizable_created(synchronizable)
      SynchronizableChangedJob.perform_later(synchronizable)
    end

    def synchronizable_updated(synchronizable)
      if synchronizable.change_is_significative_to_sequence?
        synchronizable.increment_sequence!
      end

      # Even if sequence remains the same the synchronizable may be removed
      # from some Folder, so we have to always enqueue the job
      SynchronizableChangedJob.perform_later(synchronizable)
    end

    def synchronizable_destroyed(synchronizable)
      folder_service.destroy_elements(synchronizable, :synchronizable_destroyed)
    end

    def folder_changed(folder)
      if folder.discarded?
        raise "folder discarded"
      end
      FolderSyncJob.perform_later(folder)
    end

    def folder_discarded(folder)
      FolderDestroyJob.perform_later(folder)
    end

    private

    # :nocov: mocked
    def folder_service
      @folder_service ||= FolderService.new
    end
    # :nocov:
  end
end
