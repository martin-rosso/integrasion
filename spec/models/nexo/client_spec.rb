# == Schema Information
#
# Table name: nexo_clients
#
#  id                        :integer          not null, primary key
#  service                   :integer
#  secret                    :string
#  tcp_status                :integer
#  brand_name                :integer
#  user_integrations_allowed :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
require 'rails_helper'

module Nexo
  describe Client do
    it 'secret is serialized' do
      client = nexo_clients(:default)
      expect(client.secret).to be_a Hash
    end
  end
end
