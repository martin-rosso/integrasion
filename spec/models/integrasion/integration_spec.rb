# == Schema Information
#
# Table name: integrasion_integrations
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  client_id    :integer          not null
#  name         :string
#  scope        :string
#  expires_at   :datetime
#  discarded_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require 'rails_helper'

module Integrasion
  describe Integration do
    subject do
      client = Client.first
      Integration.create!(user: User.first, client: client, scope: [ "auth_calendar_app_created" ])
    end

    it do
      expect { subject }.to change(Integration, :count).by(1)
    end
  end
end
