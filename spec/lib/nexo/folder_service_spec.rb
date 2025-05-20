require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

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

        it "when policy match, creates the element and enqueues the job" do
          allow(folder).to receive(:policy_match?).and_return(true)

          assert_enqueued_jobs(1, only: SyncElementJob) do
            expect { subject }.to change(Element, :count).by(1)
          end
        end

        it "when policy dont match, does nothing" do
          allow(folder).to receive(:policy_match?).and_return(false)

          assert_no_enqueued_jobs do
            expect { subject }.not_to change(Element, :count)
          end
        end
      end

      context "when the event was previously synced" do
        let(:event) { events(:initialized) }
        let(:element) { nexo_elements(:unsynced_local_change) }

        it "when still matches, it doesnt flag for deletion" do
          # TODO!: remove mocks to policy_still_match?
          allow(element).to receive(:policy_still_match?).and_return(true)
          allow(folder_service).to receive(:find_element).and_return(element)
          assert_enqueued_jobs(1, only: SyncElementJob) do
            expect { subject }.not_to change(element, :flagged_for_deletion?)
          end
        end

        it "when doesnt match anymore, it gets flagged for deletion" do
          allow(element).to receive(:policy_still_match?).and_return(false)
          allow(folder_service).to receive(:find_element).and_return(element)
          assert_enqueued_jobs(1, only: SyncElementJob) do
            expect { subject }.to change(element, :flagged_for_deletion?).to(true)
          end
        end

        context "when event is conflicted" do
          let(:event) { events(:conflicted) }
          let(:element) { nexo_elements(:conflicted) }

          it "raises exception" do
            allow(folder_service).to receive(:find_element).and_return(element)
            assert_no_enqueued_jobs do
              expect { subject }.to raise_error(Nexo::Errors::ElementConflicted)
                                      .and(not_change(element, :flagged_for_deletion?))
            end
          end
        end
      end
    end

    describe "destroy_elements" do
      subject do
        folder_service.destroy_elements(event, :no_longer_included_in_folder)
      end

      let(:event) { events(:initialized) }
      let(:elements) { event.nexo_elements }

      it "marks all elements as flagged for deletion and enqueues a job for each" do
        assert_enqueued_jobs(elements.count, only: SyncElementJob) do
          expect { subject }.to change { elements.pluck(:flag_deletion).uniq }.to([ true ])
        end
      end
    end
  end
end
