require "rails_helper"

module Nexo
  describe Synchronizable do
    describe "protocols" do
      it "includes the nexo_calendar_event protocol" do
        event = Event.new
        expect(event.protocols).to eq [ :nexo_calendar_event ]
      end

      pending "with more than one protocol"
    end

    describe "protocol_methods" do
      it "includes the methos from Synchronizable and CalendarEvent" do
        event = Event.new
        expect(event.protocol_methods).to include :uuid
        expect(event.protocol_methods).to include :date_from
      end
    end

    describe "method_missing" do
      let(:dummy_event) do
        aux = Class.new
        aux.include Nexo::CalendarEvent
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
  end
end
