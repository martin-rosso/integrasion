require "rails_helper"

module Nexo
  describe GoogleAuthService do
    let(:integration) { create(:nexo_integration) }

    describe "token_info" do
      let(:service) { described_class.new(integration) }

      before do
        mock_get_credentials
        mok = Google::Apis::Oauth2V2::Tokeninfo.new(email: "test@host.com")
        allow_any_instance_of(Google::Apis::Oauth2V2::Oauth2Service).to receive(:tokeninfo).and_return(mok)
      end

      it "returns the token info" do
        inf = service.token_info
        expect(inf.email).to eq "test@host.com"
      end
    end

    describe "revoke_authorization!" do
      let(:service) { described_class.new(integration) }

      it "revokes the integration" do
        authorizer_mock = instance_double(Google::Auth::WebUserAuthorizer, revoke_authorization: nil)
        allow(service).to receive(:authorizer).and_return(authorizer_mock)

        service.revoke_authorization!

        expect(authorizer_mock).to have_received(:revoke_authorization).with(integration)
      end
    end
  end
end
