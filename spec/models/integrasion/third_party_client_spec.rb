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
#  available_scopes          :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
require 'rails_helper'

module Integrasion
  describe ThirdPartyClient do
    it 'available_scopes is serialized' do
      client = ThirdPartyClient.first
      expect(client.available_scopes).to be_a Array
    end
  end
end
