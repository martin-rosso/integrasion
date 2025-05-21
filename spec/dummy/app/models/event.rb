class Event < ApplicationRecord
  include Nexo::CalendarEvent

  after_initialize do
    self.sequence = 0 if sequence.nil?
  end
end
