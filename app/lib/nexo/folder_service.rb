module Nexo
  # Handles the composition of folders
  #
  # Responsabilities:
  # - Creation of Element's
  # - Flagging Element's for removal
  # - Triggering the SyncElementJob
  class FolderService
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
        element.flag_for_removal!(reason)

        SyncElementJob.perform_later(element)
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
          folder:
        )
        Nexo.logger.debug { "Element created" }

        SyncElementJob.perform_later(element)
      else
        Nexo.logger.debug { "Policy not applies, skipping creation" }
      end
    end

    def sync_element(element)
      synchronizable = element.synchronizable

      if synchronizable.conflicted?
        raise Nexo::Errors::ElementConflicted, element
      end

      # Check if Synchronizable still must be included in folder
      if !element.policy_still_applies?
        element.flag_for_removal!(:no_longer_included_in_folder)
      end

      SyncElementJob.perform_later(element)
    end
  end
end
