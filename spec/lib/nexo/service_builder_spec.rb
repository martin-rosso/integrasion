require "rails_helper"

module Nexo
  describe ServiceBuilder do
    let(:service_builder) { described_class.instance }

    describe "build_protocol_service" do
      let(:folder) { create(:nexo_folder) }

      it do
        service = service_builder.build_protocol_service(folder)
        expect(service).to be_a GoogleCalendarService
      end
    end
  end
end
