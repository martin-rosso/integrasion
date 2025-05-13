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

    def change_is_significative_to_sequence?
      # FIXME: implementar
      true
    end

    # TODO: refactor https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
    included do
      include Nexo::Synchronizable::Associations
    end
  end
end
