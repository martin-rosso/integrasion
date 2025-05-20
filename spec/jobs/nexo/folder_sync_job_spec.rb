require "rails_helper"

module Nexo
  describe FolderSyncJob, type: :job do
    let(:folder) { nexo_folders(:default) }

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    it do
      folder_service_mock = instance_double(FolderService, find_element_and_sync: nil)
      allow_any_instance_of(described_class).to receive(:folder_service).and_return(folder_service_mock)

      described_class.perform_now(folder)

      expect(folder_service_mock).to have_received(:find_element_and_sync).exactly(6).times
    end
  end
end
