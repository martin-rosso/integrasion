FactoryBot.define do
  factory :nexo_token, class: "Nexo::Token" do
    association :integration, factory: :nexo_integration
    secret { ENV.fetch('SEED_GOOGLE_APIS_TOKEN') }
    nt_status { "active" }
    environment { "test" }
  end
end
