require "rails_helper"

module Nexo
  describe EventReceiver do
    include ActiveJob::TestHelper

    let(:event_receiver) { described_class.new }
    let(:event) { events(:with_nil_sequence) }

    describe "synchronizable_created" do
      subject do
        event_receiver.synchronizable_created(event)
      end

      it "initializes the sequence" do
        expect { subject }.to change(event, :sequence).to 0
      end

      it "enqueues the synchronizable changed job" do
        assert_enqueued_jobs(1, only: SynchronizableChangedJob) do
          subject
        end
      end

      it "with present sequence it raises exception" do
        event.sequence = 0
        expect { subject }.to raise_error(Errors::InvalidSynchronizableState)
      end

      it "with present uuid it raises exception" do
        event.uuid = "123"
        expect { subject }.to raise_error(Errors::InvalidSynchronizableState)
      end
    end

    describe "synchronizable_updated" do
      subject do
        event_receiver.synchronizable_updated(event)
      end

      it "when change is not significative" do
        allow(event).to receive(:change_is_significative_to_sequence?).and_return(false)
        allow(event).to receive(:increment_sequence!)

        assert_enqueued_jobs(1, only: SynchronizableChangedJob) do
          subject
        end

        expect(event).not_to have_received(:increment_sequence!)
        expect(event).to have_received(:change_is_significative_to_sequence?)
      end

      it "when change is significative increments the sequence" do
        allow(event).to receive(:change_is_significative_to_sequence?).and_return(true)
        allow(event).to receive(:increment_sequence!)

        assert_enqueued_jobs(1, only: SynchronizableChangedJob) do
          subject
        end

        expect(event).to have_received(:increment_sequence!)
        expect(event).to have_received(:change_is_significative_to_sequence?)
      end
    end

    describe "synchronizable_destroyed" do
      subject do
        event_receiver.synchronizable_destroyed(event)
      end

      it "when change is not significative" do
        folder_service_mock = instance_double(FolderService, destroy_elements: nil)
        allow(event_receiver).to receive(:folder_service).and_return(folder_service_mock)

        subject

        expect(folder_service_mock).to have_received(:destroy_elements)
      end
    end

    describe "folder_rule_changed" do
      subject do
        event_receiver.folder_rule_changed(folder_rule)
      end

      let(:folder_rule) { }

      pending "when change is not significative" do
        assert_enqueued_jobs(1, only: FolderSyncJob) do
          subject
        end
      end
    end
  end
end
