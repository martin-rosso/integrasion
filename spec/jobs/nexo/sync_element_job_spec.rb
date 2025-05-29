require "rails_helper"

module Nexo
  describe SyncElementJob, type: :job do
    subject do
      described_class.perform_later(element)
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    context "when flagged for deletion" do
      it "when synchronizable is present, enqueues the job" do
        element = create(:nexo_element, :flagged_for_removal)
        assert_enqueued_jobs(1, only: DeleteRemoteResourceJob) do
          described_class.perform_later(element)
        end
      end

      it "when synchronizable is ghosted, enqueues the job" do
        element = create(:nexo_element, :flagged_for_removal, :with_ghost_synchronizable)
        assert_enqueued_jobs(1, only: DeleteRemoteResourceJob) do
          described_class.perform_later(element)
        end
      end
    end

    context "when already synced" do
      let(:element) { create(:nexo_element, :synced) }

      it do
        assert_no_enqueued_jobs do
          subject
        end
      end
    end

    context "when local change to export" do
      let(:element) { create(:nexo_element, :unsynced_local_change) }

      it do
        assert_enqueued_jobs(1, only: UpdateRemoteResourceJob) do
          subject
        end
      end
    end

    context "when element is discarded" do
      let(:element) { create(:nexo_element, :discarded) }

      it do
        expect { subject }.to raise_error(Errors::ElementDiscarded)
      end
    end

    context "when synchronizable is blank" do
      let(:element) { create(:nexo_element, :with_ghost_synchronizable) }

      it do
        expect { subject }.to raise_error(Errors::SynchronizableNotFound)
      end
    end

    context "when synchronizable is conflicted" do
      let(:element) { create(:nexo_element, :conflicted_indirectly) }

      it do
        expect { subject }.to raise_error(Errors::SynchronizableConflicted)
      end
    end

    context "when element is conflicted" do
      let(:element) { create(:nexo_element, :conflicted) }

      it do
        expect { subject }.to raise_error(Errors::ElementConflicted)
      end
    end

    context "when synchronizable sequence is nil" do
      let(:element) { create(:nexo_element, :synced) }

      it do
        allow_any_instance_of(Event).to receive(:sequence).and_return(nil)
        expect { subject }.to raise_error(Errors::SynchronizableSequenceIsNull)
      end
    end
  end
end
