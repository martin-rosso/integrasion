require "rails_helper"

module Nexo
  describe SynchronizableChangedJob, type: :job do
    subject do
      described_class.perform_later(event)
    end

    before do
      create_list(:nexo_folder, 2, :with_rule_matching_all)
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    let(:event) { create(:event) }


    it "calls the folder service with each folder" do
      folder_service_mock = instance_double(FolderService, find_element_and_sync: nil)
      allow_any_instance_of(described_class).to receive(:folder_service).and_return(folder_service_mock)
      subject
      expect(folder_service_mock).to have_received(:find_element_and_sync).twice
    end

    it "folder_service" do
      service = described_class.new.send(:folder_service)
      expect(service).to be_a FolderService
    end
  end
end
