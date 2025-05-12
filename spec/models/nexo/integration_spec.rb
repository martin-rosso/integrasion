# == Schema Information
#
# Table name: nexo_integrations
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

module Nexo
  describe Integration do
    subject do
      client = Client.first
      described_class.create!(user: User.first, client: client, scope: [ "auth_calendar_app_created" ])
    end

    it do
      expect { subject }.to change(described_class, :count).by(1)
    end

    describe "token_status" do
      subject do
        integration.token_status
      end

      let(:client) { Client.first }

      let(:integration) do
        described_class.create!(user: User.first, client: client, scope: [ "auth_calendar_app_created" ])
      end

      it do
        credentials_mock = instance_double(Google::Auth::UserRefreshCredentials)
        allow(credentials_mock).to receive(:expires_at).and_return(1.minute.ago)
        allow(integration).to receive(:credentials).and_return(credentials_mock)
        expect(subject).to eq :expired_token
      end
    end
  end
end
