require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

module Nexo
  describe FetchRemoteResourceJob, type: :job do
    pending "when ActiveRecord::RecordNotUnique due to sequence"
    pending "when ActiveRecord::RecordNotUnique due to etag"

    subject do
      described_class.perform_later(element).tap do
        synchronizable.reload
      end
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    let!(:element) { create(:nexo_element, :synced) }
    let(:remote_service_mock) do
      mock = instance_double(GoogleCalendarService)
      allow(mock).to receive(:get_event).and_return(response)
      allow(mock).to receive(:fields_from_version).and_return(fields)
      mock
    end
    let(:fields) { { summary: "foo" } }
    let(:response) { instance_double(ApiResponse, etag: Time.current.to_f.to_s, payload: { "status" => "ok" }, id: "fooid") }
    let!(:synchronizable) { element.synchronizable }

    before do
      allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(remote_service_mock)
    end

    shared_examples "when there is new version from remote server" do
      it "creates a version" do
        expect do
          begin
            subject
          rescue
          end
        end.to change(ElementVersion, :count).by(1)
      end
    end

    context "when local is synced" do
      it_behaves_like "when there is new version from remote server"

      it "updates synchronizable" do
        expect { subject }.to change(synchronizable, :summary).to("foo")
      end
    end

    context "when there is an internal pending_sync version" do
      before do
        create(:nexo_element_version, :unsynced_local_change, element:)
      end

      it_behaves_like "when there is new version from remote server"

      it "not updates the synchronizable" do
        # expect { subject }.not_to change(synchronizable, :summary)
        expect { subject }.to raise_error(Errors::ElementConflicted)
        expect(remote_service_mock).not_to have_received(:fields_from_version)
        expect(element.reload).to be_conflicted
      end
    end

    context "when the synchronizable update fails" do
      let(:fields) { { summary: "this is an invalid value" } }

      it_behaves_like "when there is new version from remote server"

      it "sets ne_status to pending_external_sync" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        expect(element.reload).to be_pending_external_sync
      end
    end

    context "when no new version from remote server" do
      let(:response) { nil }

      it "not updates the synchronizable" do
        expect { subject }.not_to change(ElementVersion, :count)
      end
    end
  end
end
