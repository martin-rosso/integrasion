module Nexo
  module CalendarEvent
    include Synchronizable

    extend ActiveSupport::Concern

    define_protocol(:nexo_calendar_event, %i[
      date_from
      date_to
      time_from
      time_to
      summary
      description
    ])

    # :nocov: FIXME
    def change_is_significative_to_sequence?
      true
    end
    # :nocov:

    # TODO: refactor https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
    included do
      include Nexo::Synchronizable::Associations
    end
  end
end
