module Nexo
  class EventReceiver
    # Synchronizable created locally, must not be called when the system
    # is notified of an external element creation
    def synchronizable_created(synchronizable)
      validate_null_sequence_and_uuid!

      # Y si es un external element?
      synchronizable.update!(sequence: 0, uuid: UUID.generate)

      SynchronizableChangedJob.perform_async(synchronizable)
    end

    # Synchronizable updated locally, must not be called when the system
    # is notified of an external element update
    def synchronizable_updated(synchronizable)
      # FIXME: revisar
      if change_is_significative_to_ical?
        synchronizable.increment_sequence!
      end

      SynchronizableChangedJob.perform_async(synchronizable)
    end

    # Synchronizable destroyed locally, must not be called when the system
    # is notified of an external element destroy
    def synchronizable_destroyed(synchronizable)
      FolderService.destroy_elements(synchronizable, :synchronizable_destroyed)
    end

    def folder_rule_changed(folder_rule)
      FolderSyncJob.perform_async(folder_rule.folder)
    end
  end
end
