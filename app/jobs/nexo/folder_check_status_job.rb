module Nexo
  class FolderCheckStatusJob < BaseJob
    def perform(folder)
      calendar = GoogleCalendarService.new(folder.integration).get_calendar(folder)
      folder.update(nf_status: :ok)
    rescue StandardError => e
      folder.update(nf_status: :not_found)
    end
  end
end
