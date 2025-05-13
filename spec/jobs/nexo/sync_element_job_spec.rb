require "rails_helper"

module Nexo
  describe SyncElementJob, type: :job do
    subject do
      described_class.perform_now(element)
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    context "when flagged for deletion" do
      let(:element) { nexo_elements(:flagged_for_deletion) }

      it do
        assert_enqueued_jobs(1, only: DeleteRemoteResourceJob) do
          subject
        end
      end
    end

    context "when already synced" do
      let(:element) { nexo_elements(:synced) }

      it do
        assert_no_enqueued_jobs do
          subject
        end
      end
    end

    context "when local change to export" do
      let(:element) { nexo_elements(:unsynced_local_change) }

      it do
        assert_enqueued_jobs(1, only: UpdateRemoteResourceJob) do
          subject
        end
      end
    end

    context "when element is discarded" do
      let(:element) { nexo_elements(:discarded) }

      it do
        expect { subject }.to raise_error(Errors::ElementDiscarded)
      end
    end

    context "when synchronizable is blank" do
      let(:element) { nexo_elements(:with_ghost_synchronizable) }

      it do
        expect { subject }.to raise_error(Errors::SynchronizableNotFound)
      end
    end

    context "when synchronizable is conflicted" do
      let(:element) { nexo_elements(:conflicted_indirectly) }

      it do
        expect { subject }.to raise_error(Errors::SynchronizableConflicted)
      end
    end

    context "when element is conflicted" do
      let(:element) { nexo_elements(:conflicted) }

      it do
        expect { subject }.to raise_error(Errors::ElementConflicted)
      end
    end

    context "when synchronizable sequence is nil" do
      let(:element) { nexo_elements(:with_nil_sequence) }

      it do
        expect { subject }.to raise_error(Errors::SynchronizableSequenceIsNull)
      end
    end
  end
end
