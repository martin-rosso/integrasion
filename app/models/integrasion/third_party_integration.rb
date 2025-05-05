# == Schema Information
#
# Table name: integrasion_third_party_integrations
#
#  id                                :integer          not null, primary key
#  user_id                           :integer          not null
#  integrasion_third_party_client_id :integer          not null
#  third_party_id_user               :string
#  scope                             :string
#  expires_at                        :datetime
#  tpi_status                        :integer
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
module Integrasion
  class ThirdPartyIntegration < ApplicationRecord
    serialize :scope, coder: JSON
    belongs_to :user
    belongs_to :integrasion_third_party_client, class_name: "Integrasion::ThirdPartyClient"

    alias third_party_client integrasion_third_party_client

    enum :tpi_status, pending: 0, authorized: 1, disabled: 2, expired: 3
  end
end
