module Integrasion
  ThirdPartyClient.delete_all

  available_scopes = [ 'Google::Apis::CalendarV3::AUTH_CALENDAR_APP_CREATED' ]
  ThirdPartyClient.create(
    service: :google_calendar, available_scopes:, user_integrations_allowed: true,
    tcp_status: :authorized, secret: ENV.fetch('GOOGLE_APIS_SECRET')
  )
end
