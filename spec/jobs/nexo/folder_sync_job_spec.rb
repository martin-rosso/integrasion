require "rails_helper"

module Nexo
  describe FolderSyncJob, type: :job do
    let(:folder) { nexo_folders(:default) }
    let(:folder_service_mock) { instance_double(FolderService, find_element_and_sync: nil) }
    let(:calendar_service_mock) do
      response = ApiResponse.new(id: "folder-id")
      instance_double(GoogleCalendarService, insert_calendar: response, update_calendar: response)
    end

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end



    before do
      allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(calendar_service_mock)
      allow_any_instance_of(described_class).to receive(:folder_service).and_return(folder_service_mock)
    end

    context "when folder is created" do
      before do
        folder.update!(external_identifier: nil)
      end

      it do
        expect { described_class.perform_now(folder) }.to change(folder, :external_identifier).to("folder-id")
        expect(folder_service_mock).to have_received(:find_element_and_sync).exactly(6).times
        expect(calendar_service_mock).to have_received(:insert_calendar)
      end
    end

    context "when folder is updated" do
      before do
        folder.update!(external_identifier: "some-id")
      end

      it do
        described_class.perform_now(folder)
        expect(folder_service_mock).to have_received(:find_element_and_sync).exactly(6).times
        expect(calendar_service_mock).to have_received(:update_calendar)
      end
    end
  end
end
