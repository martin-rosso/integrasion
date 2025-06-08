require "rails_helper"

module Nexo
  describe UpdateRemoteResourceJob, type: :job do
    subject do
      described_class.perform_later(element_version)
    end

    let(:element) { element_version.element }

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    pending "when ActiveRecord::RecordNotUnique"

    context "when element doesnt exists on remote server" do
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change) }

      it do
        response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" }, id: "fooid")
        remote_service_mock = instance_double(GoogleCalendarService, insert: response)
        allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(remote_service_mock)

        expect { subject }.to change { element_version.reload.etag }.to("abc123")
                              .and(change { element.reload.uuid }.to("fooid"))

        expect(remote_service_mock).to have_received(:insert).with(element)
        expect(element_version.reload.payload).to eq({ "status" => "ok" })
      end
    end

    context "when element was synced previously on remote server" do
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, :element_previously_synced) }

      before do
        element.synchronizable.increment_sequence!
      end

      it do
        response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" })
        remote_service_mock = instance_double(GoogleCalendarService, update: response)
        allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(remote_service_mock)

        expect { subject }.to change { element_version.reload.etag }.to("abc123")
          .and(change { element_version.reload.payload }.to({ "status" => "ok" }))

        expect(remote_service_mock).to have_received(:update)
      end
    end

    pending "when etag is present"
    pending "when element version is external"

    context "when element is conflicted" do
      let(:element) { create(:nexo_element, :conflicted) }
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, element: element) }

      it do
        expect { subject }.to raise_error(Errors::ElementConflicted)
      end
    end

    context "when synchronizable is ghosted" do
      let(:element) { create(:nexo_element, :with_ghost_synchronizable) }
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, element: element) }

      it do
        expect { subject }.to raise_error(Errors::SynchronizableNotFound)
      end
    end

    context "when element is discarded" do
      let(:element) { create(:nexo_element, :discarded) }
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, element: element) }

      it do
        expect { subject }.to raise_error(Errors::ElementDiscarded)
      end
    end

    context "when synchronizable is discarded" do
      let(:element) { create(:nexo_element) }
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, element: element) }

      before do
        allow_any_instance_of(Event).to receive(:discarded?).and_return(true)
      end

      it do
        expect { subject }.to raise_error(Errors::SynchronizableDiscarded)
      end
    end

    context "when folder is discarded" do
      let(:element) { create(:nexo_element) }
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, element: element) }

      before do
        element.folder.discard!
      end

      it do
        expect { subject }.to raise_error(Errors::FolderDiscarded)
      end
    end
  end
end
