module Nexo
  # Handles synchronization of an Element. Its called anytime there is an internal or external change
  #
  # Always must be executed asynchronously to ensure the concurrency limit applies
  #
  # Responsabilities:
  #   - Triggering the GoogleCallerJob
  #   - Removing Element's
  #   - Flagging Synchronizable's as conflicted
  #   - Creation of ElementVersion's
  #   - Updating Synchronizable's on external incoming changes
  #
  # TODO: implement external ElementVersion creation
  class SyncElementJob < BaseJob
    limits_concurrency key: ->(element) { element.gid }

    # TODO: handle Element destroyed (igual no debería pasar porque siempre se descartarían)
    def perform(element)
      if element.discarded?
        # TODO: handle, si hay un external incoming change habría que flagear el Element
        # si no hay cambios que sincronizar, se podría loguear un "already synced element" y ya
      end

      if element.marked_for_deletion?
        # possible reasons:
        #   - no_longer_included_in_folder
        #   - synchronizable_destroyed


        # esto debería realizarse asincronicamente con una queue de menor prioridad y
        # con un polling_interval alto, para no saturar la API externa
        # El problema es que ya deja de ser transaccional!
        # Igualmente la transacción no incluye lo que haga Google, así que no sé.

        # FIXME: qué pasa si el synchronizable.marked_as_conficted?

        GoogleDestroyJob.perform_async(element)

        element.discard!

        return
      end

      if element.synchronizable.blank?
        raise Errors::SynchronizableNotFound, "should be marked for deletion?"
      end

      if element.synchronizable.marked_as_conficted?
        raise "sync conflicted"

        return
      end

      current_sequence = element.synchronizable.sequence
      last_synced_sequence = element.last_synced_sequence

      if element.external_unsynced_change?
        if current_sequence == last_synced_sequence
          sync_to_local_element(element)
        elsif current_sequence > last_synced_sequence
          report_conflicted_element!(element)
        else
          report_sequence_bigger_than_current_one!
        end
      else
        if current_sequence == last_synced_sequence
          pg_info "Element already synced: #{element.gid}"
        elsif current_sequence > last_synced_sequence
          export_element(element)
        else
          report_sequence_bigger_than_current_one!
        end
      end
    rescue StandardError => e
      raise Errors::SynchronizationError, e
    end

    private

    def report_conflicted_element!(element)
      element.synchronizable.mark_as_conflicted!
    end

    def sync_to_local_element(element)
      last_external_unsynced_version = element.last_external_unsynced_version

      element.synchronizable.update_from!(last_external_unsynced_version)
    end

    def report_sequence_bigger_than_current_one!
      pg_err <<~MSG
        last_synced_sequence bigger than current_sequence. \
        Element id: #{element.id}")
      MSG
    end

    def export_element(element)
      synchronizable = element.synchronizable

      GooglePostJob.perform_async(element)
    end
  end
end
