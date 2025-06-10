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
        ElementService.new(element:).flag_for_removal!(reason)

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
        ElementService.new(element:).flag_for_removal!(:no_longer_included_in_folder)

        DeleteRemoteResourceJob.perform_later(element)
      else
        ElementService.new(element:).create_internal_version_if_none!
      end
    end

    def create_and_sync_element(folder, synchronizable)
      must_be_included = folder.policy_applies?(synchronizable)

      if must_be_included
        ElementService.new.create_element_for!(folder, synchronizable)
      else
        Nexo.logger.debug { "Policy not applies, skipping creation" }
      end
    end
  end
end
