module Nexo
  # Handles synchronization of an Element. Its called anytime there is an internal or external change
  #
  # Always must be executed asynchronously to ensure the concurrency limit applies
  #
  # Responsabilities:
  # - Triggering the DeleteRemoteResourceJob
  # - Triggering the UpdateRemoteResourceJob
  # - Removing/discarding Element's
  # - Flagging Synchronizable's as conflicted
  # - Updating Synchronizable's on external incoming changes
  #
  # TODO: implement external ElementVersion creation, not here, on another place
  class SyncElementJob < BaseJob
    limits_concurrency key: ->(element) { element.to_gid }

    # TODO!: set priority based on date distance to today

    # discard_on Errors::SyncElementJobError
    # retry_on StandardError, wait: :polynomially_longer

    def perform(element)
      validate_element_state!(element)

      if element.flagged_for_deletion?
        DeleteRemoteResourceJob.perform_later(element)

        element.discard!
      else
        current_sequence = element.synchronizable.sequence
        last_synced_sequence = element.last_synced_sequence

        if element.external_unsynced_change?
          # :nocov: TODO
          raise Errors::SyncElementJobError, "not yet implemented"
          # :nocov:

          # if current_sequence == last_synced_sequence
          #   sync_to_local_element(element)
          # elsif current_sequence > last_synced_sequence
          #   element.flag_as_conflicted!
          # else
          #   # :nocov: type: borderline
          #   report_sequence_bigger_than_current_one!
          #   # :nocov:
          # end
        else
          if current_sequence == last_synced_sequence
            # TODO: log "Element already synced: #{element.to_gid}"
          elsif current_sequence > last_synced_sequence
            UpdateRemoteResourceJob.perform_later(element)
          else
            # :nocov: borderline
            raise Errors::LastSyncedSequenceBiggerThanCurrentOne, element
            # :nocov:
          end
        end
      end
    end

    private

    def validate_element_state!(element)
      if element.discarded?
        # TODO: maybe check the case of external incoming changes to flag the element as conflicted
        raise Errors::ElementDiscarded, element
      end

      if element.synchronizable.blank? && !element.flagged_for_deletion?
        # element should have been flagged for deletion
        raise Errors::SynchronizableNotFound, element
      end

      if element.conflicted?
        raise Errors::ElementConflicted, element
      end

      if element.synchronizable.present? && element.synchronizable.conflicted?
        raise Errors::SynchronizableConflicted, element
      end

      if element.synchronizable.present? && element.synchronizable.sequence.nil?
        raise Errors::SynchronizableSequenceIsNull, element
      end
    end

    # def sync_to_local_element(element)
    #   last_external_unsynced_version = element.last_external_unsynced_version

    #   element.synchronizable.update_from!(last_external_unsynced_version)
    # end
  end
end
