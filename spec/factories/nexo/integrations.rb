# == Schema Information
#
# Table name: nexo_integrations
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  client_id    :bigint           not null
#  name         :string
#  scope        :string
#  expires_at   :datetime
#  discarded_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :nexo_integration, class: "Nexo::Integration" do
    user
    association :client, factory: :nexo_client
    name { "Default integration" }
    scope { [ "auth_calendar_app_created" ] }
  end
end
