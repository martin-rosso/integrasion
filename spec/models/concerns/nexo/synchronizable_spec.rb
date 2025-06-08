require "rails_helper"

module Nexo
  describe Synchronizable do
    it "events factory works" do
      expect { create(:event) }.to change(Event, :count).by(1)
    end

    it "users factory works" do
      expect { create(:user) }.to change(User, :count).by(1)
    end

    it "conflicted trait works" do
      event = create(:event, :conflicted)
      expect(event).to be_conflicted
    end

    describe "protocols" do
      it "includes the nexo_calendar_event protocol" do
        event = Event.new
        expect(event.protocols).to eq [ :nexo_calendar_event ]
      end

      # pending "with more than one protocol"
    end

    describe "protocol_methods" do
      it "includes the methos from Synchronizable and CalendarEvent" do
        event = Event.new
        expect(event.protocol_methods).to include :sequence
        expect(event.protocol_methods).to include :date_from
      end
    end

    describe "method_missing" do
      let(:dummy_event) do
        aux = Class.new do
          def self.has_many(*, **); end
          include Nexo::CalendarEvent
        end
        aux.new
      end

      it "when calling date_from raises InterfaceMethodNotImplemented" do
        expect { dummy_event.date_from }.to raise_error(Errors::InterfaceMethodNotImplemented)
      end

      it "when calling a random inexistent method" do
        subject = lambda do
          dummy_event.other_method(:arg1, :arg2)
        end

        expect { subject.call }.to raise_error(NoMethodError)
      end
    end

    describe "increment_sequence!" do
      let(:event) { create(:event) }

      it "increments the sequence atomicly" do
        event2 = Event.find(event.id)
        event2.increment_sequence!
        new_value = event2.sequence
        expect { event.increment_sequence! }.to change { Event.find(event.id).sequence }.to(new_value + 1)

        # the in-memory value is inconsistent, this is a known issue
        expect(event.sequence).to eq new_value
      end

      context "when sequence is nil" do
        before do
          event.update(sequence: nil)
        end

        it do
          allow(Rails.logger).to receive(:warn).and_call_original
          event.increment_sequence!
          expect(Rails.logger).to have_received(:warn).with(/sequence is nil/)
        end
      end
    end

    describe "update_from!" do
      subject do
        event.update_from!(element_version)
      end

      let(:event) { create(:event) }
      let(:element) { create(:nexo_element, synchronizable: event) }

      pending "when ActiveRecord::RecordNotUnique"

      context "all-day" do
        let(:element_version) { create(:nexo_element_version, :all_day, :unsynced_external_change, element:) }

        it "when its an all-day event" do
          expect { subject }.to change { element_version.reload.sequence }.to(be_present)
            .and(change { event.reload.summary }.to("test-summary"))
            .and(change { event.reload.date_from }.to(Date.parse("2025-06-05")))
            .and(change { event.reload.date_to }.to(Date.parse("2025-06-06")))
        end
      end

      context "when event has time / i.e.: not an all-day event" do
        let(:element_version) { create(:nexo_element_version, :with_time, :unsynced_external_change, element:) }

        it "when it has time" do
          expect { subject }.to change { element_version.reload.sequence }.to(be_present)
            .and(change { event.reload.summary }.to("test-summary"))
            .and(change { event.reload.date_from }.to(Date.parse("2025-06-11")))
            .and(change { event.reload.date_to }.to(Date.parse("2025-06-11")))
            .and(change { event.reload.time_from }.to(Time.parse("2000-01-01T10:00")))
            .and(change { event.reload.time_to }.to(Time.parse("2000-01-01T14:30")))
        end
      end
    end
    # pending "conflicted?"
  end
end
