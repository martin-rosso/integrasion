require "rails_helper"

module Nexo
  describe CalendarEvent do
    let(:event) { create(:event).reload }

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
