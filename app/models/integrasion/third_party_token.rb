# == Schema Information
#
# Table name: integrasion_third_party_tokens
#
#  id                         :integer          not null, primary key
#  third_party_integration_id :integer          not null
#  id_user                    :string
#  secret                     :json
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
module Integrasion
  class ThirdPartyToken < ApplicationRecord
    belongs_to :third_party_integration, class_name: "Integrasion::ThirdPartyIntegration"

    encrypts :secret

    validates :id_user, :secret, presence: true
  end
end
