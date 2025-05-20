module Nexo
  # This callbacks must be called when synchronizables change locally, must not
  # be called when the system is notified of an external element change
  class EventReceiver
    def synchronizable_created(synchronizable)
      validate_synchronizable_state!(synchronizable)

      synchronizable.update!(sequence: 0)

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

    # TODO: implement
    # def folder_policy_changed(folder_policy)
    #   FolderSyncJob.perform_later(folder_policy.folder)
    # end

    private

    # :nocov: mocked
    def folder_service
      @folder_service ||= FolderService.new
    end
    # :nocov:

    def validate_synchronizable_state!(synchronizable)
      unless synchronizable.sequence.nil?
        raise Errors::InvalidSynchronizableState, "sequence is present: #{synchronizable.sequence}"
      end
    end
  end
end
