FactoryBot.define do
  factory :nexo_client, class: "Nexo::Client" do
    service { "google" }
    nc_status { "authorized" }
    secret { JSON.parse(ENV.fetch('SEED_GOOGLE_APIS_CLIENT_SECRET')) }
  end
end
