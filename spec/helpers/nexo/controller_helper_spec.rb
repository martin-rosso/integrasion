require "rails_helper"

module Nexo
  describe ControllerHelper, type: :helper  do
    let(:params) do
      ActionController::Parameters.new(
        integration: integration_params
      )
    end

    subject do
      nexo_integration_params(params)
    end

    context "with valid params" do
      let(:integration_params) do
        {
          name: "uno",
          scope: [ "auth_email" ]
        }
      end

      it do
        expect(subject[:name]).to eq "uno"
      end
    end

    context "without scope" do
      let(:integration_params) do
        {
          name: "name"
        }
      end

      it do
        expect { subject }.to raise_error(Nexo::Errors::InvalidParamsError)
      end
    end
  end
end
