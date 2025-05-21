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
      # FIXME: define an alternative array of methods to compare
      previous_changes.keys.map(&:to_sym).intersection(protocol_methods).any?
    end

    def datetime_from
      build_date_time(date_from, time_from)
    end

    def datetime_to
      build_date_time(date_to, time_to)
    end

    private

    # @param [Date] date
    # @param [Time] time
    #
    # @return [Date, DateTime]
    def build_date_time(date, time = nil)
      if time.present?
        DateTime.new(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.min,
          time.sec,
          time.zone
        )
      else
        date
      end
    end


    # TODO: refactor https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
    included do
      include Nexo::Synchronizable::Associations
    end
  end
end
