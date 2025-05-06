# == Schema Information
#
# Table name: integrasion_third_party_integrations
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  third_party_client_id :integer          not null
#  name                  :string
#  scope                 :string
#  expires_at            :datetime
#  discarded_at          :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'rails_helper'

module Integrasion
  describe ThirdPartyIntegration do
    subject do
      client = ThirdPartyClient.first
      ThirdPartyIntegration.create!(user: User.first, third_party_client: client, scope: [ "auth_calendar_app_created" ])
    end

    it do
      expect { subject }.to change(ThirdPartyIntegration, :count).by(1)
    end
  end
end
