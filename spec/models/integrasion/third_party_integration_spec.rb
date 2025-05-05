require 'rails_helper'

module Integrasion
  describe ThirdPartyIntegration do
    subject do
      client = ThirdPartyClient.first
      ThirdPartyIntegration.create!(user: User.first, integrasion_third_party_client: client)
    end

    it do
      expect { subject }.to change(ThirdPartyIntegration, :count).by(1)
    end
  end
end
