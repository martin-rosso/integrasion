require "rails_helper"

module Nexo
  describe FolderService do
    include ActiveJob::TestHelper

    let(:folder_service) do
      described_class.new
    end

    describe "find_element_and_sync" do
      subject do
        folder_service.find_element_and_sync(folder, event)
      end

      let(:folder) { nexo_folders(:default) }

      context "when the event is not yet synced" do
        let(:event) { events(:not_yet_synced) }

        it "when rules match, creates the element and enqueues the job" do
          allow(folder).to receive(:rules_match?).and_return(true)

          assert_enqueued_jobs(1, only: SyncElementJob) do
            expect { subject }.to change(Element, :count).by(1)
          end
        end

        it "when rules dont match, does nothing" do
          allow(folder).to receive(:rules_match?).and_return(false)

          assert_no_enqueued_jobs do
            expect { subject }.not_to change(Element, :count)
          end
        end
      end

      context "when the event was previously synced" do
        let(:event) { events(:initialized) }
        let(:element) { nexo_elements(:unsynced_local_change) }

        it "when still matches, it doesnt flag for deletion" do
          allow(element).to receive(:rules_still_match?).and_return(true)
          allow(folder_service).to receive(:find_element).and_return(element)
          assert_enqueued_jobs(1, only: SyncElementJob) do
            expect { subject }.not_to change(element, :flagged_for_deletion?)
          end
        end

        it "when doesnt match anymore, it gets flagged for deletion" do
          allow(element).to receive(:rules_still_match?).and_return(false)
          allow(folder_service).to receive(:find_element).and_return(element)
          assert_enqueued_jobs(1, only: SyncElementJob) do
            expect { subject }.to change(element, :flagged_for_deletion?).to(true)
          end
        end

        context "when event is conflicted" do
          let(:event) { events(:conflicted) }

          it "does nothing" do
            assert_no_enqueued_jobs do
              expect { subject }.not_to change(element, :flagged_for_deletion?)
            end
          end
        end
      end
    end

    # describe "sync_element" do
    #   subject do
    #     folder_service.send(:sync_element, element)
    #   end

    #   let(:element) { nexo_elements(:unsynced_local_change) }

    #   it do
    #     allow(element).to receive(:rules_still_match?).and_return(true)
    #     assert_enqueued_jobs(1, only: SyncElementJob) do
    #       subject
    #     end
    #   end
    # end
  end
end
