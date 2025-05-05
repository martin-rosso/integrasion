module Integrasion
  ThirdPartyClient.delete_all
  User.delete_all

  secret = JSON.parse(ENV.fetch('SEEDS_GOOGLE_APIS_SECRET'))
  ThirdPartyClient.create(
    service: :google_calendar, user_integrations_allowed: true,
    tcp_status: :authorized, secret:
  )

  User.create(email: 'user@test.com', password: '123456')
end
