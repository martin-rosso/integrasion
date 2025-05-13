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
      previous_changes.keys.map(&:to_sym).intersection(protocol_methods).any?
    end

    # TODO: refactor https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
    included do
      include Nexo::Synchronizable::Associations
    end
  end
end
