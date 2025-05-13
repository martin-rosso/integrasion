module Nexo
  # Handles the composition of folders
  #
  # Responsabilities:
  #   - Creation of Element's
  #   - Flagging Element's for deletion
  #   - Triggering the SyncElementJob
  class FolderService
    def find_element_and_sync(folder, synchronizable)
      element = find_element(folder, synchronizable)

      if element.present?
        sync_element(element)
      else
        create_and_sync_element(folder, synchronizable)
      end
    end

    def destroy_elements(synchronizable, reason)
      synchronizable.nexo_elements.each do |element|
        element.flag_for_deletion!(reason)

        SyncElementJob.perform_later(element)
      end
    end

    private

    def find_element(folder, synchronizable)
      folder.find_element(synchronizable:)
    end

    def create_and_sync_element(folder, synchronizable)
      must_be_included = folder.rules_match?(synchronizable)

      if must_be_included
        element = Element.create!(
          synchronizable:,
          folder:
        )

        SyncElementJob.perform_later(element)
      end
    end

    def sync_element(element)
      synchronizable = element.synchronizable

      if synchronizable.conflicted?
        # FIXME: pg_warn("sync conflicted")

        return
      end

      # Check if Synchronizable still must be included in folder
      if !element.rules_still_match?
        element.flag_for_deletion!(:no_longer_included_in_folder)
      end

      SyncElementJob.perform_later(element)
    end
  end
end
