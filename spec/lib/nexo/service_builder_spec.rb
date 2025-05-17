require "rails_helper"

module Nexo
  describe ServiceBuilder do
    let(:service_builder) { described_class.instance }

    describe "build_remote_service" do
      let(:folder) { nexo_folders(:default) }

      it do
        service = service_builder.build_remote_service(folder)
        expect(service).to be_a GoogleCalendarService
      end
    end
  end
end
