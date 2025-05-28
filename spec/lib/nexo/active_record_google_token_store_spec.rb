require "rails_helper"

module Nexo
  describe ActiveRecordGoogleTokenStore do
    let(:integration) do
      create(:nexo_integration)
    end

    let(:store) { described_class.new }

    describe "load" do
      before do
        Token.create!(secret: "secret-token", integration:)
      end

      it do
        secret = store.load(integration)
        expect(secret).to eq "secret-token"
      end
    end

    describe "delete" do
      let!(:token) do
        Token.create!(secret: "secret-token", integration:)
      end

      it do
        expect { store.delete(integration) }.to change { token.reload.nt_status }.to("revoked")
      end
    end

    describe "store" do
      it do
        expect { store.store(integration, "secret-stored") }.to change(Token, :count).by(1)
      end
    end
  end
end
