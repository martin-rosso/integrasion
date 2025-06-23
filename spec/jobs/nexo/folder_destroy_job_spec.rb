require "rails_helper"

module Nexo
  describe FolderDestroyJob, type: :job do
    subject do
      described_class.perform_later(folder)
    end

    let(:folder) { create :nexo_folder }

    around do |example|
      perform_enqueued_jobs(only: described_class) do
        example.run
      end
    end

    it "calls the API" do
      response = instance_double(ApiResponse, etag: "abc123", payload: { "status" => "ok" })
      service_mock = instance_double(GoogleCalendarService, remove_calendar: response)
      allow(ServiceBuilder.instance).to receive(:build_protocol_service).and_return(service_mock)

      subject

      expect(service_mock).to have_received(:remove_calendar).with(folder)
    end

    it "when folder doesn't have external_identifier" do
      folder.update(external_identifier: nil)

      allow(ServiceBuilder).to receive(:instance)
      subject
      expect(ServiceBuilder).not_to have_received(:instance)
    end
  end
end
