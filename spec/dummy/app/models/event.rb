class Event < ApplicationRecord
  include Nexo::CalendarEvent
  include Nexo::Synchronizable::Relations
end
