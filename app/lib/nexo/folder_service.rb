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
      validate_synchronizable!(synchronizable)

      element = folder.find_element(synchronizable:)

      if element.present?
        Nexo.logger.debug { "Element found" }
        validate_element_state!(element)
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

    def validate_synchronizable!(synchronizable)
      synchronizable.validate_synchronizable!

      if synchronizable.sequence.nil?
        raise Errors::SynchronizableSequenceIsNull
      end
    end

    def validate_element_state!(element)
      # unless element.synced?
      #   raise Errors::Error, <<~STR
      #     element ne_status is invalid: #{element.ne_status} \
      #     (should be synced)
      #   STR
      # end
    end

    def sync_element(element)
      if !element.policy_still_applies?
        Nexo.logger.debug("Flagging for removal and enqueuing DeleteRemoteResourceJob")
        # TODO!: the reason for this? just monitoring?
        element.flag_for_removal!(:no_longer_included_in_folder)

        DeleteRemoteResourceJob.perform_later(element)
      else
        if element.element_versions.where(sequence: element.synchronizable.sequence).none?
          handle_new_internal_version(element)
        else
          Nexo.logger.debug { "There is a version for current sequence, nothing to do" }
        end
      end
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

    def handle_new_internal_version(element)
      # TODO!: maybe some lock here?
      element_version = ElementVersion.create!(
        element:,
        origin: :internal,
        sequence: element.synchronizable.sequence,
        nev_status: :pending_sync
      )
      Nexo.logger.debug { "ElementVersion created" }

      element.update_ne_status!

      if element.pending_local_sync?
        Nexo.logger.debug { "Enqueuing UpdateRemoteResourceJob" }
        UpdateRemoteResourceJob.perform_later(element_version)
      elsif element.conflicted?
        Nexo.logger.info { "Element conflicted, so not enqueuing UpdateRemoteResourceJob" }
      else
        Nexo.logger.warn { "Element status is: #{element.ne_status}. That's weird" }
      end
    end
  end
end
