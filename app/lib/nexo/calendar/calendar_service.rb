module Nexo
  class CalendarService
    attr_accessor :integration

    def initialize(integration)
      @integration = integration
    end
  end
end
