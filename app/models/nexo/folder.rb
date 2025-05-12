# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :integer          not null, primary key
#  integration_id      :integer          not null
#  protocol            :integer          not null
#  external_identifier :string
#  name                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
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
