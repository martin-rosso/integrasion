module Nexo
  # Wrapper around +Google::Apis::CalendarV3+
  #
  # TODO: handle ServerError to be retried
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  #   possible messages:
  #   - duplicate: The requested identifier already exists.
  #   - notFound: Not Found (calendar not exists or was deleted)
  #   - forbidden: Forbidden (event to update was deleted)
  #   - conditionNotMet: Precondition Failed (etag / if-match header verification failed)
  #   - invalid: Invalid sequence value. The specified sequence number is below
  #              the current sequence number of the resource. Re-fetch the resource and
  #              use its sequence number on the following request.
  #   - deleted: Resource has been deleted
  #
  # TODO! when event to update was deleted, create a new one and warn
  class GoogleCalendarService < CalendarService
    # Create an event in a Google Calendar
    #
    # @param [Element] folder
    #
    def insert(element)
      validate_folder_state!(element.folder)

      event = build_event(element)
      response = client.insert_event(element.folder.external_identifier, event)
      ApiResponse.new(payload: response.to_h, status: :ok, etag: response.etag, id: response.id)
    end

    # Update an event in a Google Calendar
    def update(element)
      validate_folder_state!(element.folder)
      # sidebranch
      # TODO!: validate uuid presence

      event = build_event(element)

      response = client.update_event(element.folder.external_identifier, element.uuid, event, options: ifmatch_options(element))

      ApiResponse.new(payload: response.to_h, status: :ok, etag: response.etag)
    rescue Google::Apis::ClientError => e
      if e.message.match? /conditionNotMet/
        raise Errors::ConflictingRemoteElementChange, e
      else
        raise
      end
    end

    # Delete an event in a Google Calendar
    def remove(element)
      validate_folder_state!(element.folder)
      # sidebranch
      # TODO!: validate uuid presence

      # TODO: try with cancelled / maybe its the same
      client.delete_event(element.folder.external_identifier, element.uuid, options: ifmatch_options(element))
      ApiResponse.new(payload: nil, status: :ok, etag: nil)
    rescue Google::Apis::ClientError => e
      if e.message.match? /conditionNotMet/
        raise Errors::ConflictingRemoteElementChange, e
      else
        raise
      end
    end

    def get_event(element)
      validate_folder_state!(element.folder)
      return nil unless element.uuid.present?

      # would be nice to send If-None-Match header, but Google API doesn't seem
      # to accept it
      response = client.get_event(element.folder.external_identifier, element.uuid)

      ApiResponse.new(payload: response.to_h, status: :ok, etag: response.etag, id: response.id)
    rescue Google::Apis::ClientError => e
      if e.message.match? "notFound"
        Nexo.logger.warn("Event not found for #{element.to_gid}")
        nil
      else
        raise
      end
    end

    def get_calendar(folder)
      validate_folder_state!(folder)

      response = client.get_calendar(folder.external_identifier)
      ApiResponse.new(payload: response.to_h, status: :ok, etag: response.etag, id: response.id)
    end

    # Create a Google calendar
    def insert_calendar(folder)
      validate_folder_state!(folder, verify_external_identifier_presence: false)

      cal = build_calendar(folder)
      response = client.insert_calendar(cal)
      ApiResponse.new(payload: response.to_h, status: :ok, etag: response.etag, id: response.id)
    end

    # Update a Google calendar
    def update_calendar(folder)
      validate_folder_state!(folder)

      cal = build_calendar(folder)
      response = client.update_calendar(folder.external_identifier, cal)
      ApiResponse.new(payload: response.to_h, status: :ok, etag: response.etag, id: response.id)
    end

    def remove_calendar(folder)
      validate_folder_state!(folder)

      client.delete_calendar(folder.external_identifier)
      ApiResponse.new(status: :ok)
    end

    def watch_calendar(folder)
      channel = Google::Apis::CalendarV3::Channel.new(
        id: "123-321",
        token: "the-token-312",
        type: "web_hook",
        address: "https://bien.com.ar:8001/google_webhook",
      )
      client.watch_event(folder.external_identifier, channel)

      # Return value example:
      # {"expiration"=>1753894903000,
      #  "id"=>"123-321",
      #  "kind"=>"api#channel",
      #  "resource_id"=>"tzPO9NflP22ZgQxNejOk9TZVCvA",
      #  "resource_uri"=>
      #   "https://www.googleapis.com/calendar/v3/calendars/e2b0e85c7aa97c8d30b81f9a4e6cac6cd95aa0ca5e06bca31ae47995e79a546d%40group.calendar.google.com/events?alt=json",
      #  "token"=>"the-token-312"}

      # Headers to parse
      #
      #
      # Sync request (initial request)
      #
      # {
      #   host: 'bien.com.ar:8001',
      #   accept: '*/*',
      #   'x-goog-channel-id': '123-321',
      #   'x-goog-channel-expiration': 'Wed, 30 Jul 2025 17:01:43 GMT',
      #   'x-goog-resource-state': 'sync',
      #   'x-goog-message-number': '1',
      #   'x-goog-resource-id': 'tzPO9NflP22ZgQxNejOk9TZVCvA',
      #   'x-goog-resource-uri': 'https://www.googleapis.com/calendar/v3/calendars/e2b0e85c7aa97c8d30b81f9a4e6cac6cd95aa0ca5e06bca31ae47995e79a546d%40group.calendar.google.com/events?alt=json',
      #   'x-goog-channel-token': 'the-token-312',
      #   'content-length': '0',
      #   connection: 'keep-alive',
      #   'user-agent': 'APIs-Google; (+https://developers.google.com/webmasters/APIs-Google.html)',
      #   'accept-encoding': 'gzip, deflate, br'
      # }
      #
      #
      #
      #
      # Event change requests
      #
      # POST /google_webhook 200 4.552 ms - 2
      # {
      #   host: 'bien.com.ar:8001',
      #   accept: '*/*',
      #   'x-goog-channel-id': '123-321',
      #   'x-goog-channel-expiration': 'Wed, 30 Jul 2025 17:01:43 GMT',
      #   'x-goog-resource-state': 'exists',
      #   'x-goog-message-number': '332449',
      #   'x-goog-resource-id': 'tzPO9NflP22ZgQxNejOk9TZVCvA',
      #   'x-goog-resource-uri': 'https://www.googleapis.com/calendar/v3/calendars/e2b0e85c7aa97c8d30b81f9a4e6cac6cd95aa0ca5e06bca31ae47995e79a546d%40group.calendar.google.com/events?alt=json',
      #   'x-goog-channel-token': 'the-token-312',
      #   'content-length': '0',
      #   connection: 'keep-alive',
      #   'user-agent': 'APIs-Google; (+https://developers.google.com/webmasters/APIs-Google.html)',
      #   'accept-encoding': 'gzip, deflate, br'
      # }
      #
      # POST /google_webhook 200 2.213 ms - 2
      # {
      #   host: 'bien.com.ar:8001',
      #   accept: '*/*',
      #   'x-goog-channel-id': '123-321',
      #   'x-goog-channel-expiration': 'Wed, 30 Jul 2025 17:01:43 GMT',
      #   'x-goog-resource-state': 'exists',
      #   'x-goog-message-number': '343282',
      #   'x-goog-resource-id': 'tzPO9NflP22ZgQxNejOk9TZVCvA',
      #   'x-goog-resource-uri': 'https://www.googleapis.com/calendar/v3/calendars/e2b0e85c7aa97c8d30b81f9a4e6cac6cd95aa0ca5e06bca31ae47995e79a546d%40group.calendar.google.com/events?alt=json',
      #   'x-goog-channel-token': 'the-token-312',
      #   'content-length': '0',
      #   connection: 'keep-alive',
      #   'user-agent': 'APIs-Google; (+https://developers.google.com/webmasters/APIs-Google.html)',
      #   'accept-encoding': 'gzip, deflate, br'
      # }
      #
      # {
      #   host: 'bien.com.ar:8001',
      #   accept: '*/*',
      #   'x-goog-channel-id': '123-321',
      #   'x-goog-channel-expiration': 'Tue, 17 Jun 2025 01:29:16 GMT',
      #   'x-goog-resource-state': 'exists',
      #   'x-goog-message-number': '35574024',
      #   'x-goog-resource-id': 'n8R-BiCIoxzWnlpUXnKfyFu5skU',
      #   'x-goog-resource-uri': 'https://www.googleapis.com/calendar/v3/calendars/cbed3a3fe2e0352b59aef4f498bc15d12277ed703de7114f8acbf0774339d995%40group.calendar.google.com/events?alt=json',
      #   'x-goog-channel-token': 'the-token-312',
      #   'content-length': '0',
      #   connection: 'keep-alive',
      #   'user-agent': 'APIs-Google; (+https://developers.google.com/webmasters/APIs-Google.html)',
      #   'accept-encoding': 'gzip, deflate, br'
      # }
    end

    def stop_watching(folder, id = "123")
      channel = Google::Apis::CalendarV3::Channel.new(
        id:,
        resource_id: "n8R-BiCIoxzWnlpUXnKfyFu5skU",
      )
      client.stop_channel(channel)
    end

    def payload_readonly?(payload)
      # when event_type is not present, it means that the Event was definitely
      # destroyed. It is expected that summary is also blank, and start and end
      # dates are faked (not the original event dates)
      payload[:event_type].blank?
    end

    def fields_from_payload(payload)
      event = validate_version!(payload)

      {
        date_from: parse_date(event.start),
        date_to: parse_date(event.end),
        time_from: parse_time(event.start),
        time_to: parse_time(event.end),
        summary: event.summary,
        description: event.description,

        # Posible status values:
        # - confirmed
        # - tentative
        # - cancelled (deleted)
        status: event.status
      }
    end

    private

    def validate_version!(payload)
      event_data = ActiveSupport::HashWithIndifferentAccess.new(payload)
      event = Google::Apis::CalendarV3::Event.new(**event_data)

      validate_datetime!(event.start)
      validate_datetime!(event.end)

      event
    end

    def parse_date(datetime)
      if datetime["date"].present?
        Date.parse(datetime["date"])
      else
        Date.parse(datetime["date_time"])
      end
    end

    def parse_time(datetime)
      if datetime["date"].present?
        nil
      else
        Time.parse(datetime["date_time"])
      end
    end

    def validate_datetime!(datetime)
      unless datetime.is_a?(Hash) && (datetime["date"].present? || datetime["date_time"].present?)
        # :nocov: borderline
        raise "invalid datetime"
        # :nocov:
      end
    end

    def validate_folder_state!(folder, verify_external_identifier_presence: true)
      unless folder.integration.token?
        raise Errors::Error, "folder has no token"
      end

      if verify_external_identifier_presence && folder.external_identifier.blank?
        raise Errors::InvalidFolderState, folder
      end
    end

    def build_event(element)
      calendar_event = element.synchronizable
      estart = build_event_date_time(calendar_event.datetime_from)
      eend = build_event_date_time(calendar_event.datetime_to)

      # TODO: sequence is managed by both google and nexo
      # google accepts the sent sequence only if its valid (>= current_sequence)
      # when we receive a remote change with updated sequence, we should
      # update the secuence accordingly. and if we receive a remote change without a
      # secuence increment, then we could:
      #   1. not update the local secuence. but maybe thats not viable
      #   2. increment the local secuence and update the remote
      #   3. increment the local secuence and not update the remote
      #   4. <current> ignore the sequence from google

      from = element.last_remote_version

      base_event =
        if from.present?
          event_data = ActiveSupport::HashWithIndifferentAccess.new(from.payload)
          Google::Apis::CalendarV3::Event.new(**event_data)
        else
          Google::Apis::CalendarV3::Event.new
        end

      base_event.update!(
        start: estart,
        end: eend,
        summary: calendar_event.summary,
        description: calendar_event.description,
        transparency: calendar_event.transparency,
        status: calendar_event.nce_status,
        # sequence: calendar_event.sequence
      )

      base_event
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

    def ifmatch_options(element)
      ifmatch = element.etag
      Nexo.logger.debug { "ifmatch: #{ifmatch}" }

      raise Errors::Error, "an etag is required to perform the request" if ifmatch.blank?

      Google::Apis::RequestOptions.new(header: { "If-Match" => ifmatch })
    end
  end
end
