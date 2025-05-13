module Nexo
  class EventReceiver
    # Synchronizable created locally, must not be called when the system
    # is notified of an external element creation
    def synchronizable_created(synchronizable)
      validate_null_sequence_and_uuid!(synchronizable)

      # Y si es un external element?
      synchronizable.update!(sequence: 0, uuid: SecureRandom.uuid)

      SynchronizableChangedJob.perform_later(synchronizable)
    end

    # Synchronizable updated locally, must not be called when the system
    # is notified of an external element update
    def synchronizable_updated(synchronizable)
      if synchronizable.change_is_significative_to_sequence?
        synchronizable.increment_sequence!
      end

      # always enqueue the job, because, even if sequence remains the same
      # the synchronizable may be removed from some Folder
      SynchronizableChangedJob.perform_later(synchronizable)
    end

    # Synchronizable destroyed locally, must not be called when the system
    # is notified of an external element destroy
    def synchronizable_destroyed(synchronizable)
      folder_service.destroy_elements(synchronizable, :synchronizable_destroyed)
    end

    def folder_rule_changed(folder_rule)
      FolderSyncJob.perform_later(folder_rule.folder)
    end

    private

    def folder_service
      @folder_service ||= FolderService.new
    end

    def validate_null_sequence_and_uuid!(synchronizable)
      unless synchronizable.sequence.nil?
        raise Errors::InvalidSynchronizableState, "sequence is present: #{synchronizable.sequence}"
      end

      unless synchronizable.uuid.nil?
        raise Errors::InvalidSynchronizableState, "uuid is present: #{synchronizable.uuid}"
      end
    end
  end
end
