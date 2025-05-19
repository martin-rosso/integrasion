require "google-apis-calendar_v3"

module Nexo
  # Wrapper around +Google::Apis::CalendarV3+
  #
  # @raise [Google::Apis::ClientError] possible messages:
  #   - duplicate: The requested identifier already exists.
  #   - notFound: Not Found
  #   - forbidden: Forbidden (cuando se intenta updatear un evento que ya fue borrado)
  class GoogleCalendarService < CalendarService
    # Create an event in a Google Calendar
    #
    # @param [Folder] folder
    #
    # @todo Debería recibir un {Element}?
    def insert(folder, calendar_event)
      event = build_event(calendar_event)
      # FIXME: if external_identifier nil raise
      response = client.insert_event(folder.external_identifier, event)
      ApiResponse.new(payload: response.to_json, status: :ok, etag: response.etag, id: response.id)
    end

    # Update an event in a Google Calendar
    def update(element)
      event = build_event(element.synchronizable)
      response = client.update_event(element.folder.external_identifier, element.uuid, event)
      ApiResponse.new(payload: response.to_json, status: :ok, etag: response.etag)
    end

    # Delete an event in a Google Calendar
    def remove(element)
      # TODO: try with cancelled
      # FIXME: if external_identifier nil raise
      client.delete_event(element.folder.external_identifier, element.uuid)
      ApiResponse.new(payload: nil, status: :ok, etag: nil)
    end

    # Create a Google calendar
    def insert_calendar(folder)
      cal = build_calendar(folder)
      response = client.insert_calendar(cal)
      ApiResponse.new(payload: response.to_json, status: :ok, etag: response.etag, id: response.id)
    end

    def remove_calendar(folder)
      client.delete_calendar(folder.external_identifier)
      ApiResponse.new(status: :ok)
    end

    # @!visibility private
    # :nocov: non-production
    def clear_calendars
      Folder.all.each do |folder|
        cid = folder.external_identifier
        events = client.list_events(cid).items
        events.each do |event|
          client.delete_event(cid, event.id)
        end
      end
    end
    # :nocov:

    private

    def build_event(calendar_event)
      estart = build_event_date_time(calendar_event.datetime_from)
      eend = build_event_date_time(calendar_event.datetime_to)

      Google::Apis::CalendarV3::Event.new(
        start: estart,
        end: eend,
        summary: calendar_event.summary,
        description: calendar_event.description
      )
    end

    def build_calendar(folder)
      cal = Google::Apis::CalendarV3::Calendar.new(
        summary: folder.name,
        description: folder.description,
        time_zone: folder.time_zone
      )
    end

    # @param [Date, DateTime] datetime
    def build_event_date_time(datetime)
      if datetime.respond_to?(:hour)
        Google::Apis::CalendarV3::EventDateTime.new(date_time: datetime)
      else
        Google::Apis::CalendarV3::EventDateTime.new(date: datetime)
      end
    end

    def client
      # :nocov: mocked
      @client ||=
        Google::Apis::CalendarV3::CalendarService.new.tap do |cli|
          cli.authorization = integration.credentials
        end
      # :nocov:
    end
  end
end
