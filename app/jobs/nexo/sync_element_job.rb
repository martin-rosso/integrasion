module Nexo
  # Handles synchronization of an Element. Its called anytime there is an internal or external change
  #
  # Always must be executed asynchronously to ensure the concurrency limit applies
  #
  # Responsabilities:
  #   - Triggering the GoogleCallerJob
  #   - Removing/discarding Element's
  #   - Flagging Synchronizable's as conflicted
  #   - Updating Synchronizable's on external incoming changes
  #
  # TODO: implement external ElementVersion creation, not here, on another place
  class SyncElementJob < BaseJob
    limits_concurrency key: ->(element) { element.gid }

    rescue_from ActiveJob::DeserializationError do |e|
      raise Errors::SyncElementJobError, e, "element couldnt be deserialized"
    end

    discard_on Errors::SyncElementJobError

    retry_on StandardError, wait: :polynomially_longer

    def perform(element)
      validate(element)

      if element.marked_for_deletion?
        DeleteRemoteResourceJob.perform_async(element)

        element.discard!
      else
        current_sequence = element.synchronizable.sequence
        last_synced_sequence = element.last_synced_sequence

        if element.external_unsynced_change?
          raise Errors::SyncElementJobError, "not yet implemented" # :nocov:

          # if current_sequence == last_synced_sequence
          #   sync_to_local_element(element)
          # elsif current_sequence > last_synced_sequence
          #   element.mark_as_conflicted!
          # else
          #   report_sequence_bigger_than_current_one!
          # end
        else
          if current_sequence == last_synced_sequence
            pg_info "Element already synced: #{element.gid}"
          elsif current_sequence > last_synced_sequence
            UpdateRemoteResourceJob.perform_async(element)
          else
            report_sequence_bigger_than_current_one!
          end
        end
      end
    end

    private

    def validate(element)
      if element.discarded?
        # TODO: handle, si hay un external incoming change habría que flagear el Element
        # si no hay cambios que sincronizar, se podría loguear un "already synced element" y ya
        raise Errors::ElementDiscarded, element
      end

      if element.synchronizable.blank? && !element.marked_for_deletion?
        # should be marked for deletion?
        raise Errors::SynchronizableNotFound, element
      end

      if element.conflicted?
        raise Errors::ElementConflicted, element
      end

      if element.synchronizable.present? && element.synchronizable.conflicted?
        raise Errors::SynchronizableConflicted, element
      end
    end

    # def sync_to_local_element(element)
    #   last_external_unsynced_version = element.last_external_unsynced_version

    #   element.synchronizable.update_from!(last_external_unsynced_version)
    # end

    def report_sequence_bigger_than_current_one!
      # FIXME: report
      # pg_err <<~MSG
      #   last_synced_sequence bigger than current_sequence. \
      #   Element id: #{element.id}")
      # MSG
    end
  end
end
