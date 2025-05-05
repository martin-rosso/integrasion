module Integrasion
  ThirdPartyClient.delete_all
  User.delete_all

  available_scopes = [ 'Google::Apis::CalendarV3::AUTH_CALENDAR_APP_CREATED' ]
  secret = ENV.fetch('SEEDS_GOOGLE_APIS_SECRET')
  ThirdPartyClient.create(
    service: :google_calendar, available_scopes:, user_integrations_allowed: true,
    tcp_status: :authorized, secret:
  )

  User.create(email: 'user@test.com', password: '123456')
end
