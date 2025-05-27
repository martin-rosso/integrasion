require "rails_helper"

module Nexo
  describe GoogleCalendarService do
    let(:google_calendar_service) { described_class.new(integration) }
    let(:integration) { nexo_integrations(:default) }

    let(:response) do
      ApiResponse.new(etag: "bla", payload: "payload", status: :ok)
    end

    before do
      client_mock = instance_double(Google::Apis::CalendarV3::CalendarService, mocks)
      allow(google_calendar_service).to receive(:client).and_return(client_mock)

      credentials_mock = instance_double(Google::Auth::UserRefreshCredentials, expires_at: 10.minutes.from_now)
      auth_service_mock = instance_double(GoogleAuthService, get_credentials: credentials_mock)
      allow(ServiceBuilder.instance).to receive(:build_auth_service).and_return(auth_service_mock)
    end

    shared_examples "folder operation" do
      context "when folder identifier is nil" do
        before do
          element.folder.update(external_identifier: nil)
        end

        it "raises error" do
          expect { subject }.to raise_error(Errors::InvalidFolderState)
        end
      end
    end

    describe "insert" do
      subject do
        google_calendar_service.insert(element.folder, element.synchronizable)
      end

      let(:mocks) do
        { insert_event: response }
      end

      let(:element) { nexo_elements(:unsynced_local_change) }

      it do
        expect(subject).to be_a ApiResponse
      end

      context "when its an all day event" do
        let(:element) { nexo_elements(:all_day_event) }

        it do
          expect(subject).to be_a ApiResponse
        end
      end

      it_behaves_like "folder operation"
    end

    describe "update" do
      subject do
        google_calendar_service.update(element)
      end

      let(:mocks) do
        { update_event: response }
      end

      let(:element) { nexo_elements(:unsynced_local_change) }

      it do
        expect(subject).to be_a ApiResponse
      end

      it_behaves_like "folder operation"
    end

    describe "remove" do
      subject do
        google_calendar_service.remove(element)
      end

      let(:mocks) do
        { delete_event: response }
      end

      let(:element) { nexo_elements(:unsynced_local_change) }

      it do
        expect(subject).to be_a ApiResponse
      end

      it_behaves_like "folder operation"
    end

    describe "insert_calendar" do
      subject do
        google_calendar_service.insert_calendar(folder)
      end

      let(:mocks) do
        { insert_calendar: response }
      end

      let(:folder) { nexo_folders(:default) }

      it do
        expect(subject).to be_a ApiResponse
      end
    end
  end
end
