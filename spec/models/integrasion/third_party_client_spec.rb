# == Schema Information
#
# Table name: integrasion_third_party_clients
#
#  id                        :integer          not null, primary key
#  service                   :integer
#  secret                    :json
#  tcp_status                :integer
#  brand_name                :integer
#  user_integrations_allowed :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
require 'rails_helper'

module Integrasion
  describe ThirdPartyClient do
    it 'secret is serialized' do
      client = ThirdPartyClient.first
      expect(client.secret).to be_a Hash
    end
  end
end
