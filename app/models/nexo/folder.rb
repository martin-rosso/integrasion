module Nexo
  class Folder < ApplicationRecord
    belongs_to :integration, class_name: "Nexo::Integration"

    enum :protocol, calendar: 0

    validates :protocol, presence: true

    def rules_match?(synchronizable)
      # FIXME: implement
      raise "implementar"
    end
  end
end
