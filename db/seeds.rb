module Integrasion
  Integration.delete_all
  User.delete_all
  Client.delete_all

  secret = JSON.parse(ENV.fetch('SEEDS_GOOGLE_APIS_SECRET'))
  Client.create!(
    service: :google, user_integrations_allowed: true,
    tcp_status: :authorized, secret:
  )

  User.create!(email: 'user@test.com', password: '123456')
end
