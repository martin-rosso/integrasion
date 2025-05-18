
require "rails_helper"

module Nexo
  describe DeleteRemoteResourceJob, type: :job do
    subject do
      described_class.perform_now(element)
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    context "when element doesnt exists on remote server" do
      let(:element) { nexo_elements(:synced) }

      it do
        response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" })
        service_mock = instance_double(GoogleCalendarService, remove: response)
        allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(service_mock)

        subject

        expect(service_mock).to have_received(:remove)
      end
    end
  end
end
