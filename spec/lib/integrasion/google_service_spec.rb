require "rails_helper"

module Integrasion
  describe GoogleService do
    let(:client) { Client.first }

    let(:integration) do
      Integration.create!(user: User.first, client: client, scope: [ "auth_calendar_app_created" ])
    end

    describe "token_info" do
      let(:service) { GoogleService.new(integration) }

      before do
        mock = double(Google::Auth::UserRefreshCredentials.new, expires_at: 10.minutes.from_now)
        allow_any_instance_of(Google::Auth::WebUserAuthorizer).to receive(:get_credentials).and_return(mock)
        mok = Google::Apis::Oauth2V2::Tokeninfo.new(email: "test@host.com")
        allow_any_instance_of(Google::Apis::Oauth2V2::Oauth2Service).to receive(:tokeninfo).and_return(mok)
      end

      it "returns the token info" do
        inf = service.token_info
        expect(inf.email).to eq "test@host.com"
      end
    end

    describe "revoke_authorization!" do
      let(:service) { GoogleService.new(integration) }

      it "revokes the integration" do
        authorizer_mock = instance_double("Google::Auth::WebUserAuthorizer")
        allow(service).to receive(:authorizer).and_return(authorizer_mock)
        expect(authorizer_mock).to receive(:revoke_authorization).with(integration)
        service.revoke_authorization!
      end
    end
  end
end
