require "rails_helper"

module Nexo
  describe GoogleCalendarService do
    let(:google_calendar_service) { described_class.new(integration) }
    let(:integration) { create(:nexo_integration) }

    shared_context "api interaction" do
      let(:response) do
        ApiResponse.new(etag: "bla", payload: "payload", status: :ok)
      end

      let(:credentials_mock) { instance_double(Google::Auth::UserRefreshCredentials, expires_at: 10.minutes.from_now) }

      let(:folder) { create(:nexo_folder) }

      let(:client_mock) { instance_double(Google::Apis::CalendarV3::CalendarService, mocks) }

      before do
        allow(google_calendar_service).to receive(:client).and_return(client_mock)

        auth_service_mock = instance_double(GoogleAuthService, get_credentials: credentials_mock)
        allow(ServiceBuilder.instance).to receive(:build_auth_service).and_return(auth_service_mock)
      end
    end

    shared_examples "folder element operation" do
      context "when folder identifier is nil" do
        before do
          element.folder.update(external_identifier: nil)
        end

        it "raises error" do
          expect { subject }.to raise_error(Errors::InvalidFolderState)
        end
      end
    end

    shared_examples "change over existing remote element" do
      context "when there is not an etag" do
        let(:element) { create(:nexo_element, :unsynced_local_change) }

        it "raises error" do
          expect { subject }.to raise_error /an etag is required/
        end
      end

      context "when the google client raises error" do
        let(:client_mock) do
          aux = instance_double(Google::Apis::CalendarV3::CalendarService)
          allow(aux).to receive(:update_event).and_raise(Google::Apis::ClientError, error_message)
          allow(aux).to receive(:delete_event).and_raise(Google::Apis::ClientError, error_message)
          aux
        end

        let(:error_message) { "notFound" }

        it "raises the same error" do
          expect { subject }.to raise_error(Google::Apis::ClientError)
        end

        context "and the error is conditionNotMet" do
          let(:error_message) { "conditionNotMet" }

          it "wraps the error" do
            expect { subject }.to raise_error(Errors::ConflictingRemoteElementChange)
          end
        end
      end
    end

    describe "insert" do
      subject do
        google_calendar_service.insert(element)
      end

      let(:element) { create(:nexo_element, :unsynced_local_change) }
      let(:mocks) do
        { insert_event: response }
      end

      include_context "api interaction"

      it do
        expect(subject).to be_a ApiResponse
      end

      context "when its an all day event" do
        let(:element) { create(:nexo_element, synchronizable: create(:event, :all_day_event)) }

        it do
          expect(subject).to be_a ApiResponse
        end
      end

      it_behaves_like "folder element operation"
    end

    describe "update" do
      subject do
        google_calendar_service.update(element)
      end

      let(:element) { create(:nexo_element, :unsynced_local_change_to_update) }
      let(:mocks) do
        { update_event: response }
      end

      include_context "api interaction"

      it do
        expect(subject).to be_a ApiResponse
      end

      it_behaves_like "folder element operation"
      it_behaves_like "change over existing remote element"
    end

    describe "remove" do
      subject do
        google_calendar_service.remove(element)
      end

      let(:element) { create(:nexo_element, :unsynced_local_change_to_update) }
      let(:mocks) do
        { delete_event: response }
      end

      include_context "api interaction"

      it "is successful" do
        expect(subject).to be_a ApiResponse
      end

      it_behaves_like "folder element operation"
      it_behaves_like "change over existing remote element"
    end

    describe "get_event" do
      subject do
        google_calendar_service.get_event(element)
      end

      let(:element) { create(:nexo_element, :unsynced_local_change_to_update) }
      let(:mocks) do
        { get_event: response }
      end

      include_context "api interaction"

      it "is successful" do
        expect(subject).to be_a ApiResponse
        expect(client_mock).to have_received(:get_event).with(instance_of(String), instance_of(String))
      end

      it_behaves_like "folder element operation"

      context "when the google client raises error" do
        let(:client_mock) do
          aux = instance_double(Google::Apis::CalendarV3::CalendarService)
          allow(aux).to receive(:get_event).and_raise(Google::Apis::ClientError, error_message)
          aux
        end

        let(:error_message) { "forbidden" }

        it "raises the same error" do
          expect { subject }.to raise_error(Google::Apis::ClientError)
        end

        context "and the error is notFound" do
          let(:error_message) { "notFound" }

          it "wraps the error" do
            expect(subject).to be_nil
          end
        end
      end
    end

    describe "#fields_from_version" do
      subject do
        google_calendar_service.fields_from_version(element_version)
      end

      context "all-day event" do
        let(:element_version) { create :nexo_element_version, :unsynced_external_change, :all_day }

        it do
          expect(subject[:time_from]).to be_blank
        end
      end

      context "event with time" do
        let(:element_version) { create :nexo_element_version, :unsynced_external_change, :with_time }

        it do
          expect(subject[:time_from]).to be_present
        end
      end
    end

    shared_examples "without credentials" do
      context "when integration has no token" do
        let(:credentials_mock) { nil }

        it "raises error" do
          expect { subject }.to raise_error /folder has no token/
        end
      end
    end

    describe "insert_calendar" do
      subject do
        google_calendar_service.insert_calendar(folder)
      end

      let(:mocks) do
        { insert_calendar: response }
      end

      include_context "api interaction"

      it do
        expect(subject).to be_a ApiResponse
      end

      it_behaves_like "without credentials"
    end

    describe "update_calendar" do
      subject do
        google_calendar_service.update_calendar(folder)
      end

      let(:mocks) do
        { update_calendar: response }
      end

      include_context "api interaction"

      it do
        expect(subject).to be_a ApiResponse
      end

      it_behaves_like "without credentials"
    end

    describe "remove_calendar" do
      subject do
        google_calendar_service.remove_calendar(folder)
      end

      let(:mocks) do
        { delete_calendar: response }
      end

      include_context "api interaction"

      it do
        expect(subject).to be_a ApiResponse
      end
    end
  end
end
