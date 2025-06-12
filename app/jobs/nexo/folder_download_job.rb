module Nexo
  class FolderDownloadJob < BaseJob
    def perform(folder, type)
      if type == "full_sync"
        GoogleCalendarSyncService.new(folder.integration).full_sync!(folder)
      elsif type == "incremental_sync"
        GoogleCalendarSyncService.new(folder.integration).incremental_sync!(folder)
      else
        raise "unknown sync type"
      end
    end
  end
end
