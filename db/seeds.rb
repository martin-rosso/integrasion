module Nexo
  ENV.fetch('SEED_GOOGLE_APIS_CLIENT_SECRET', nil) || puts("WARN: env variable SEED_GOOGLE_APIS_CLIENT_SECRET not found")
  ENV.fetch('SEED_GOOGLE_APIS_TOKEN', nil) || puts("WARN: env variable SEED_GOOGLE_APIS_TOKEN not found")

  if ENV.fetch('SEED_GOOGLE_APIS_CLIENT_SECRET', nil)
    client = Client.create!(
      tcp_status: 0,
      service: "google",
      secret: JSON.parse(ENV.fetch('SEED_GOOGLE_APIS_CLIENT_SECRET'))
    )
    user = User.first
    integration = Nexo::Integration.create!(
      user:,
      client:,
      name: "Default integration",
      scope: [ "auth_calendar_app_created" ]
    )

    if ENV.fetch('SEED_GOOGLE_APIS_TOKEN', nil)
      Nexo::Token.create!(
        integration:,
        secret: ENV.fetch('SEED_GOOGLE_APIS_TOKEN'),
        tpt_status: :active,
        environment: "development"
      )
    end
  end
end
