class Event < ApplicationRecord
  include Nexo::CalendarEvent

  after_initialize do
    self.sequence = 0 if sequence.nil?
  end

  def assign_fields!(fields)
    hsh = {
      date_from: fields[:date_from],
      time_from: fields[:time_from],
      date_to: fields[:date_to],
      time_to: fields[:time_to],
      summary: fields[:summary],
      description: fields[:description]
    }
    update!(hsh)
  end

  def discarded?
    false
  end

  def to_s
    "#{summary}"
  end
end
