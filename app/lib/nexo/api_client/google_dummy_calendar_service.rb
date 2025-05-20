# :nocov: tricky
module Nexo
  # Dummy calendar service
  class GoogleDummyCalendarService < CalendarService
    def insert(folder, calendar_event)
      puts "Dummy: Creating event '#{calendar_event.summary}'"
      ApiResponse.new(payload: "payload", status: :ok, etag: "etag", id: "dummy_id")
    end

    def update(element)
      puts "Dummy: Updating event"
      ApiResponse.new(payload: "payload", status: :ok, etag: "etag", id: "dummy_id")
    end

    def remove(element)
      puts "Dummy: Removing event"
      ApiResponse.new(payload: "payload", status: :ok, etag: "etag", id: "dummy_id")
    end

    def insert_calendar(folder)
      puts "Dummy: Creating calendar"
      ApiResponse.new(payload: "payload", status: :ok, etag: "etag", id: "dummy_id")
    end

    def remove_calendar(folder)
      puts "Dummy: Removing calendar"
      ApiResponse.new(payload: "payload", status: :ok, etag: "etag", id: "dummy_id")
    end
  end
end
# :nocov:
