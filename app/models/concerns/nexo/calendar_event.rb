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
      previous_changes.keys.map(&:to_sym).intersection(significative_columns).any?
    end

    # Model columns relevant to the sequence
    #
    # By default is equal to protocol_methods, but each concrete model class
    # could have its own specific column names
    def significative_columns
      protocol_methods
    end

    def datetime_from
      build_date_time(date_from, time_from)
    end

    def datetime_to
      build_date_time(date_to, time_to)
    end

    def all_day?
      time_from.blank? && time_to.blank?
    end

    # transparent: non blocking
    # opaque: blocking
    def transparency
      if all_day?
        "transparent"
      else
        "opaque"
      end
    end

    def validate_synchronizable!
      unless datetime_from.present?
        raise Errors::SynchronizableInvalid, "datetime_from is nil"
      end

      unless datetime_to.present?
        raise Errors::SynchronizableInvalid, "datetime_to is nil"
      end

      unless datetime_from != datetime_to
        raise Errors::SynchronizableInvalid, "datetime_from and datetime_to are equal"
      end

      unless summary.present?
        raise Errors::SynchronizableInvalid, "summary is nil"
      end
    end

    private

    # @param [Date] date
    # @param [Time] time
    #
    # @return [Date, DateTime]
    def build_date_time(date, time = nil)
      if time.present? && date.present?
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
