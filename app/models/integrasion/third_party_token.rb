# == Schema Information
#
# Table name: integrasion_third_party_tokens
#
#  id                         :integer          not null, primary key
#  third_party_integration_id :integer          not null
#  secret                     :json
#  tpt_status                 :integer          not null
#  environment                :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
module Integrasion
  class ThirdPartyToken < ApplicationRecord
    belongs_to :third_party_integration, class_name: "Integrasion::ThirdPartyIntegration"

    encrypts :secret

    enum :tpt_status, active: 0, revoked: 1, expired: 2

    validates :secret, :tpt_status, :environment, presence: true

    def expires_in
      (created_at + 1.hour - Time.zone.now).to_i
    end
  end
end
