module Nexo
  module CalendarEvent
    include Synchronizable

    define_protocol(:nexo_calendar_event, %i[
      date_from
      date_to
      time_from
      time_to
      summary
      description
    ])

    def change_is_significative_to_sequence?
      # FIXME: implementar
      true
    end
  end
end
