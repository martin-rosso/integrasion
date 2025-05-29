require "rails_helper"

module Nexo
  describe DeleteRemoteResourceJob, type: :job do
    subject do
      described_class.perform_later(element)
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    context "when element is flagged for removal" do
      let(:element) { create(:nexo_element, :synced, :flagged_for_removal) }

      it "calls the API" do
        response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" })
        service_mock = instance_double(GoogleCalendarService, remove: response)
        allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(service_mock)

        expect { subject }.to change { element.reload.discarded_at }.to be_present

        expect(service_mock).to have_received(:remove)
      end
    end

    context "when already discarded" do
      let(:element) { create(:nexo_element, :discarded) }

      it "raises error" do
        expect { subject }.to raise_error /element already discarded/
      end
    end

    context "when not flagged for removal" do
      let(:element) { create(:nexo_element) }

      it "raises error" do
        expect { subject }.to raise_error /not flagged for removal/
      end
    end
  end
end
