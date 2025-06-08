# == Schema Information
#
# Table name: nexo_tokens
#
#  id             :bigint           not null, primary key
#  integration_id :bigint           not null
#  secret         :string
#  nt_status      :integer          not null
#  environment    :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
FactoryBot.define do
  factory :nexo_token, class: "Nexo::Token" do
    association :integration, factory: :nexo_integration
    secret { ENV.fetch('SEED_GOOGLE_APIS_TOKEN') }
    nt_status { "active" }
    environment { "test" }
  end
end
