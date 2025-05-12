module Nexo
  # Handles the composition of folders
  #
  # Responsabilities:
  #   - Creation of Element's
  #   - Flagging Element's for deletion
  #   - Triggering the SyncElementJob
  class FolderService
    def find_element_and_sync(folder, synchronizable)
      element = folder.find_element!(synchronizable)

      if element.present?
        sync_element(element)
      else
        create_and_sync_element(folder, synchronizable)
      end
    end

    def create_and_sync_element(folder, synchronizable)
      must_be_included = folder.rules_match?(synchronizable)

      if must_be_included
        element = Element.create!(
          synchronizable:,
          folder:
        )

        SyncElementJob.perform_async(element)
      end
    end

    def sync_element(element)
      synchronizable = element.synchronizable

      if synchronizable.conflicted?
        pg_warn("sync conflicted")

        return
      end

      # Check if Synchronizable still must be included in folder
      must_be_included = folder.rules_match?(synchronizable)

      if !must_be_included
        element.mark_for_deletion!(:no_longer_included_in_folder)
      end

      SyncElementJob.perform_async(element)
    end

    def destroy_elements(synchronizable, reason)
      synchronizable.elements.each do |element|
        element.mark_for_deletion!(reason)

        SyncElementJob.perform_async(element)
      end
    end
  end
end
