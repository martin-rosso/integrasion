require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

module Nexo
  describe FolderService do
    include ActiveJob::TestHelper

    let(:folder_service) do
      described_class.new
    end

    pending "when ActiveRecord::RecordNotUnique"

    describe "find_element_and_sync" do
      subject do
        folder_service.find_element_and_sync(folder, event)
      end

      let(:folder) { create(:nexo_folder) }

      context "when synchronizable sequence is nil" do
        let(:element) { create(:nexo_element, :synced, folder:) }
        let(:event) { element.synchronizable }

        it do
          allow_any_instance_of(Event).to receive(:sequence).and_return(nil)
          expect { subject }.to raise_error(Errors::SynchronizableSequenceIsNull)
        end
      end

      context "when synchronizable is invalid" do
        let(:event) { create(:event, summary: nil) }

        it "raises error" do
          expect { subject }.to raise_error(Errors::SynchronizableInvalid)
        end
      end

      context "when the event is not yet synced" do
        let(:event) { create(:event, :not_yet_synced) }

        it "when policy match, creates the element and enqueues the job" do
          allow(folder).to receive(:policy_applies?).and_return(true)

          assert_enqueued_jobs(1, only: UpdateRemoteResourceJob) do
            expect { subject }.to change(Element, :count).by(1)
              .and(change(ElementVersion, :count).by(1))
          end
        end

        it "when policy dont match, does nothing" do
          allow(folder).to receive(:policy_applies?).and_return(false)

          assert_no_enqueued_jobs do
            expect { subject }.not_to change(Element, :count)
          end
        end
      end

      context "when the event was previously synced" do
        subject do
          folder_service.find_element_and_sync(folder, event)
          element.reload
        end

        let(:element) { create(:nexo_element, :synced, folder:) }
        let(:event) { element.synchronizable }

        before do
          event.increment_sequence!
        end

        it "when still matches, it doesnt flag for removal" do
          DummyFolderRule.create!(folder: element.folder, search_regex: ".*")

          assert_enqueued_jobs(1, only: UpdateRemoteResourceJob) do
            expect { subject }.to not_change(element, :flagged_for_removal?)
              .and(change(ElementVersion, :count).by(1))
          end
        end

        it "when doesnt match anymore, it gets flagged for removal" do
          assert_enqueued_jobs(1, only: DeleteRemoteResourceJob) do
            expect { subject }.to change(element, :flagged_for_removal?).to(true)
          end
        end

        context "when element has an unsynced_local_change" do
          let(:element) { create(:nexo_element, :unsynced_local_change, folder:) }

          it "creates a new version" do
            DummyFolderRule.create!(folder: element.folder, search_regex: ".*")

            assert_enqueued_jobs(1, only: UpdateRemoteResourceJob) do
              expect { subject }.to change(ElementVersion, :count).by(1)
            end
          end
        end

        context "when event is conflicted" do
          let(:element) { create(:nexo_element, :synced, :conflicted, folder:) }

          it "raises exception" do
            assert_no_enqueued_jobs do
              expect { subject }.to raise_error(Nexo::Errors::SynchronizableConflicted)
                                      .and(not_change(element, :flagged_for_removal?))
            end
          end
        end
      end
    end

    describe "destroy_elements" do
      subject do
        folder_service.destroy_elements(event, :no_longer_included_in_folder)
      end

      let(:event) { create(:event, :with_elements) }
      let(:elements) { event.nexo_elements }

      it "marks all elements as flagged for removal and enqueues a job for each" do
        assert_enqueued_jobs(elements.count, only: DeleteRemoteResourceJob) do
          expect { subject }.to change { elements.pluck(:flagged_for_removal).uniq }.to([ true ])
        end
      end
    end
  end
end
