# == Schema Information
#
# Table name: nexo_clients
#
#  id         :bigint           not null, primary key
#  service    :integer
#  secret     :string
#  tcp_status :integer
#  brand_name :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
