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
    let(:client) { nexo_clients(:default) }
    let(:user) { users(:default) }

    let(:integration) do
      described_class.create!(user:, client:, scope: [ "auth_calendar_app_created" ])
    end

    describe "expires_in" do
      subject do
        integration.expires_in
      end

      it do
        allow(integration).to receive(:credentials).and_return(nil)
        expect(subject).to be_nil
      end

      it do
        expires_at = 1.minute.from_now
        credentials_mock = instance_double(Google::Auth::UserRefreshCredentials, expires_at:)
        allow(integration).to receive(:credentials).and_return(credentials_mock)
        expect(subject).to be_a Integer
      end
    end

    describe "token_status" do
      subject do
        integration.token_status
      end

      let(:integration) do
        aux = described_class.create!(user: User.first, client: client, scope: [ "auth_calendar_app_created" ])
        credentials_mock = instance_double(Google::Auth::UserRefreshCredentials, expires_at:)
        allow(aux).to receive(:credentials).and_return(credentials_mock)
        aux
      end

      context "when no token" do
        let(:expires_at) { 1.minute.ago }

        it do
          allow(integration).to receive(:credentials).and_return(nil)
          expect(subject).to eq :no_token
        end
      end

      context "when expired" do
        let(:expires_at) { 1.minute.ago }

        it do
          expect(subject).to eq :expired_token
        end
      end

      context "when not expired" do
        let(:expires_at) { 1.minute.from_now }

        it do
          expect(subject).to eq :active_token
        end
      end
    end
  end
end
