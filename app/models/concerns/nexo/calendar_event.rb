module Nexo
  module CalendarEvent
    # extend ActiveSupport::Concern
    include Synchronizable

    define_protocol(:nexo_calendar_event, %i[
      date_from
      date_to
      time_from
      time_to
      summary
      description
    ])
  end
end
