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

    shared_context "when hits the api" do
      before do
        allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(remote_service_mock)
      end

      let(:remote_service_mock) do
        response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" }, id: "fooid")
        instance_double(GoogleCalendarService, insert: response, update: response)
      end
    end

    context "when element doesnt exists on remote server" do
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change) }

      include_context "when hits the api"

      it do
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

      include_context "when hits the api"

      it do
        expect { subject }.to change { element_version.reload.etag }.to("abc123")
          .and(change { element_version.reload.payload }.to({ "status" => "ok" }))

        expect(remote_service_mock).to have_received(:update).with(element)
      end
    end

    context "when element was modified on remote" do
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, :element_previously_synced) }

      include_context "when hits the api"

      before do
        element.synchronizable.increment_sequence!
        allow(remote_service_mock).to receive(:update).and_raise(Errors::ConflictingRemoteElementChange)
      end

      it do
        assert_enqueued_jobs(1, only: FetchRemoteResourceJob) do
          subject
        end
      end
    end

    context "validating" do
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change) }

      it "when etag is present raises error" do
        element_version.update(etag: "foo")
        expect { subject }.to raise_error /etag must be blank/
      end

      it "when element is synced, raises error" do
        element_version.element.update(ne_status: :synced)
        expect { subject }.to raise_error /invalid ne_status/
      end

      it "when element version is external, raises error" do
        element_version.update(origin: :external)
        expect { subject }.to raise_error /must be internal/
      end

      it "when element version is not pending_sync, raises error" do
        element_version.update(nev_status: :synced)
        expect { subject }.to raise_error /must be pending_sync/
      end
    end

    context "when version is superseded" do
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change) }

      it "raises error and superseds the version" do
        create(:nexo_element_version, :synced, origin: :internal, element:, sequence: element_version.sequence + 1)

        expect { subject }.to raise_error /version superseded/
        expect(element_version.reload).to be_superseded
      end
    end

    context "when element is conflicted" do
      let(:element) { create(:nexo_element, :conflicted) }
      let(:element_version) { create(:nexo_element_version, :unsynced_local_change, element: element) }

      it do
        expect { subject }.to raise_error(Errors::UpdateRemoteVersionFailed, "synchronizable conflited")
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
