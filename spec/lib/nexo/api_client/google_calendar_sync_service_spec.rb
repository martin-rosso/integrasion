require "rails_helper"

module Nexo
  describe GoogleCalendarSyncService do
    let(:service) { described_class.new(integration) }
    let(:integration) { create(:nexo_integration) }
    let(:folder) { create(:nexo_folder) }
    let(:cal_id) { folder.external_identifier }

    let(:client_mock) { instance_double(Google::Apis::CalendarV3::CalendarService) }

    let(:events) do
      [
        Google::Apis::CalendarV3::Events.new(
          items: [event1, event2],
          next_page_token: "page-token-1",
        ),
        Google::Apis::CalendarV3::Events.new(
          items: [event3, event4],
          next_page_token: "page-token-2",
        ),
        Google::Apis::CalendarV3::Events.new(
          items: [event5],
          next_sync_token: "next-sync-token-1"
        ),
        nil
      ]
    end

    def build_fake_event(element)
      date = Faker::Date.forward
      Google::Apis::CalendarV3::Event.new(
        id: element.uuid,
        etag: Time.current.to_f.to_s,
        start: {
          date:,
        },
        end: {
          date: date + 1.day,
        },
        summary: Faker::Lorem.sentence,
        description: Faker::Lorem.sentence,
      )
    end

    let(:element1) { create :nexo_element, :synced, folder: }
    let(:element2) { create :nexo_element, :synced, folder: }
    let(:element3) { create :nexo_element, :synced, folder: }
    let(:element4) { create :nexo_element, :synced, folder: }
    let(:element5) { create :nexo_element, :synced, folder: }

    let(:event1) { build_fake_event(element1) }
    let(:event2) { build_fake_event(element2) }
    let(:event3) { build_fake_event(element3) }
    let(:event4) { build_fake_event(element4) }
    let(:event5) { build_fake_event(element5) }

    before do
      allow(client_mock).to receive(:list_events).and_return(*events)
      allow(service).to receive(:client).and_return(client_mock)
    end

    describe "#full_sync!" do
      subject do
        service.full_sync!(folder)
        folder.reload
      end

      it do
        expect { subject }.to change(folder, :google_next_sync_token).to eq "next-sync-token-1"

        expect(client_mock).to have_received(:list_events)
          .with(cal_id, sync_token: nil, page_token: nil).ordered
        expect(client_mock).to have_received(:list_events)
          .with(cal_id, sync_token: nil, page_token: "page-token-1").ordered
        expect(client_mock).to have_received(:list_events)
          .with(cal_id, sync_token: nil, page_token: "page-token-2").ordered
        expect(client_mock).to have_received(:list_events).exactly(3).times

      end

      it do
        expect { subject }.to change(ElementVersion, :count).by(5)
          .and(change { element1.synchronizable.reload.summary })
      end
    end

    describe "#incremental_sync!" do
      subject do
        service.incremental_sync!(folder)
      end

      let(:folder) { create(:nexo_folder, google_next_sync_token: "sync-token-1") }

      it do
        expect { subject }.to change(folder, :google_next_sync_token).to eq "next-sync-token-1"

        expect(client_mock).to have_received(:list_events)
          .with(cal_id, sync_token: "sync-token-1", page_token: nil).ordered
        expect(client_mock).to have_received(:list_events)
          .with(cal_id, sync_token: nil, page_token: "page-token-1").ordered
        expect(client_mock).to have_received(:list_events)
          .with(cal_id, sync_token: nil, page_token: "page-token-2").ordered
        expect(client_mock).to have_received(:list_events).exactly(3).times
      end

      it do
        expect { subject }.to change(ElementVersion, :count).by(5)
          .and(change { element1.synchronizable.reload.summary })
      end
    end
  end
end
