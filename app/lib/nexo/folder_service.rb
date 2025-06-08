module Nexo
  # Handles the composition of folders
  #
  # Responsabilities:
  # - Creation of Element's
  # - Creation of ElementVersion on local changes
  # - Flagging Element's for removal
  # - Enqueues UpdateRemoteResourceJob, DeleteRemoteResourceJob
  class FolderService
    # @raise [ActiveRecord::RecordNotUnique] on ElementVersion creation
    def find_element_and_sync(folder, synchronizable)
      synchronizable.validate_synchronizable!

      # TODO: handle conflicted synchronizable
      element = find_element(folder, synchronizable)

      if element.present?
        Nexo.logger.debug { "Element found" }
        sync_element(element)
      else
        Nexo.logger.debug { "Element not found" }
        create_and_sync_element(folder, synchronizable)
      end
    end

    def destroy_elements(synchronizable, reason)
      synchronizable.nexo_elements.each do |element|
        # TODO!: the reason for this? just monitoring?
        element.flag_for_removal!(reason)

        DeleteRemoteResourceJob.perform_later(element)
      end
    end

    private

    def find_element(folder, synchronizable)
      folder.find_element(synchronizable:)
    end

    def create_and_sync_element(folder, synchronizable)
      must_be_included = folder.policy_applies?(synchronizable)

      if must_be_included
        element = Element.create!(
          synchronizable:,
          folder:,
          ne_status: :pending_local_sync
        )
        Nexo.logger.debug { "Element created" }

        handle_new_internal_version(element)
      else
        Nexo.logger.debug { "Policy not applies, skipping creation" }
      end
    end

    def sync_element(element)
      synchronizable = element.synchronizable

      if synchronizable.conflicted?
        raise Nexo::Errors::ElementConflicted, element
      end

      if !element.policy_still_applies?
        # TODO!: the reason for this? just monitoring?
        element.flag_for_removal!(:no_longer_included_in_folder)

        DeleteRemoteResourceJob.perform_later(element)
      else
        handle_new_internal_version(element)
      end
    end

    def handle_new_internal_version(element)
      # FIXME: ensure this is only executed when synchronizable has changed and
      # incremented his sequence
      version = create_internal_element_version(element)

      element.update_ne_status!

      OldSyncElement.new.perform(version)
    end

    def create_internal_element_version(element)
      # TODO!: maybe some lock here?
      ElementVersion.create!(
        element:,
        origin: :internal,
        sequence: element.synchronizable.sequence,
        nev_status: :pending_sync
      ).tap do
        Nexo.logger.debug { "ElementVersion created" }
      end
    end
  end

  # FIXME: rename or merge to previous class
  class OldSyncElement
    def perform(element_version)
      validate_element_state!(element_version.element)

      UpdateRemoteResourceJob.perform_later(element_version)
    end

    private

    # FIXME: refactor and move to find_element_and_sync
    # specialmente el SynchronizableSequenceIsNull
    def validate_element_state!(element)
      if element.discarded?
        # TODO: maybe check the case of external incoming changes to flag the element as conflicted
        raise Errors::ElementDiscarded, element
      end

      unless element.pending_local_sync?
        raise Errors::Error, "element ne_status is invalid: #{element.ne_status} (should be pending_local_sync)"
      end

      if element.synchronizable.present? && element.synchronizable.conflicted?
        raise Errors::SynchronizableConflicted, element
      end

      if element.synchronizable.present? && element.synchronizable.sequence.nil?
        raise Errors::SynchronizableSequenceIsNull, element
      end
    end
  end
end
