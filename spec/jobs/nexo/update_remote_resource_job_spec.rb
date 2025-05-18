require "rails_helper"

module Nexo
  describe UpdateRemoteResourceJob, type: :job do
    subject do
      described_class.perform_now(element)
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    context "when element doesnt exists on remote server" do
      let(:element) { nexo_elements(:unsynced_local_change) }

      it do
        response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" })
        remote_service_mock = instance_double(GoogleCalendarService, insert: response)
        allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(remote_service_mock)

        expect { subject }.to change(ElementVersion, :count).by(1)

        expect(remote_service_mock).to have_received(:insert)
        expect(ElementVersion.last.etag).to eq "abc123"
        expect(ElementVersion.last.payload).to eq({ "status" => "ok" })
      end
    end

    context "when element was synced previously on remote server" do
      let(:element) { nexo_elements(:synced) }

      before do
        element.synchronizable.increment_sequence!
      end

      it do
        response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" })
        remote_service_mock = instance_double(GoogleCalendarService, update: response)
        allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(remote_service_mock)

        expect { subject }.to change(ElementVersion, :count).by(1)

        expect(remote_service_mock).to have_received(:update)
        expect(ElementVersion.last.etag).to eq "abc123"
        expect(ElementVersion.last.payload).to eq({ "status" => "ok" })
      end
    end

    context "when element is already synced" do
      let(:element) { nexo_elements(:synced) }

      it do
        expect { subject }.to raise_error(Errors::ElementAlreadySynced)
      end
    end

    context "when element is conflicted" do
      let(:element) { nexo_elements(:conflicted) }

      it do
        expect { subject }.to raise_error(Errors::ElementConflicted)
      end
    end

    context "when there is an external unsynced change" do
      let(:element) { nexo_elements(:unsynced_external_change) }

      it do
        expect { subject }.to raise_error(Errors::ExternalUnsyncedChange)
      end
    end
  end
end
