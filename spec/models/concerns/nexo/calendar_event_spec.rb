require "rails_helper"

module Nexo
  describe CalendarEvent do
    let(:event) { create(:event).reload }

    describe "validate_synchronizable!" do
      subject { event.validate_synchronizable! }

      context "when datetime_from is nil" do
        let(:event) { create(:event, date_from: nil) }

        it "raises error" do
          expect { subject }.to raise_error Errors::SynchronizableInvalid
        end
      end

      context "when datetime_to is nil" do
        let(:event) { create(:event, date_to: nil) }

        it "raises error" do
          expect { subject }.to raise_error Errors::SynchronizableInvalid
        end
      end

      context "when summary is nil" do
        let(:event) { create(:event, summary: nil) }

        it "raises error" do
          expect { subject }.to raise_error Errors::SynchronizableInvalid
        end
      end

      context "when datetime_from is equal to datetime_to" do
        let(:date) { Date.today }
        let(:event) { create(:event, :all_day_event, date_from: date, date_to: date) }

        it "raises error" do
          expect { subject }.to raise_error Errors::SynchronizableInvalid
        end
      end
    end

    describe "change_is_significative_to_sequence?" do
      subject do
        event.change_is_significative_to_sequence?
      end

      it do
        expect(subject).to be_falsey
      end

      it do
        event.update(updated_at: Time.current)
        expect(subject).to be_falsey
      end

      it do
        event.update(summary: "foo")
        expect(subject).to be_truthy
      end
    end
  end
end
