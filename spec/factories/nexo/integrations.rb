FactoryBot.define do
  factory :nexo_integration, class: "Nexo::Integration" do
    user
    association :client, factory: :nexo_client
    name { "Default integration" }
    scope { [ "auth_calendar_app_created" ] }
  end
end
