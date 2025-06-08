# == Schema Information
#
# Table name: nexo_clients
#
#  id         :bigint           not null, primary key
#  service    :integer
#  secret     :string
#  nc_status  :integer
#  brand_name :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :nexo_client, class: "Nexo::Client" do
    service { "google" }
    nc_status { "authorized" }
    secret { JSON.parse(ENV.fetch('SEED_GOOGLE_APIS_CLIENT_SECRET')) }
  end
end
