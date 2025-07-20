class Event < ApplicationRecord
  include Nexo::CalendarEvent

  after_initialize do
    self.sequence = 0 if sequence.nil?
  end

  validate do
    if summary&.match? "this is an invalid value"
      errors.add(:summary, "invalid value")
    end
  end

  def update_from_fields!(fields)
    if fields[:status] == "cancelled"
      Nexo.logger.debug("Event status is 'cancelled', destroying event")
      destroy!
    else
      hsh = translate_fields(fields)
      update!(hsh)
    end
  end

  def nce_status
    discarded? ? "cancelled" : "confirmed"
  end

  def translate_fields(fields, for_create: false, folder: nil)
    {
      date_from: fields[:date_from],
      time_from: fields[:time_from],
      date_to: fields[:date_to],
      time_to: fields[:time_to],
      summary: fields[:summary],
      description: fields[:description]
    }
  end

  def discarded?
    false
  end

  def to_s
    "#{summary}"
  end
end
