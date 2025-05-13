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
    has_many :elements, class_name: "Nexo::Element"

    enum :protocol, calendar: 0

    validates :protocol, presence: true

    # :nocov: TODO!, not yet being called
    def rules_match?(synchronizable)
      # TODO!: implement
      true
    end
    # :nocov:

    def find_element(synchronizable:)
      elements.where(synchronizable:).first
    end
  end
end
