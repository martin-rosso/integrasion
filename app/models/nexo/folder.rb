# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :integer          not null, primary key
#  integration_id      :integer          not null
#  protocol            :integer          not null
#  external_identifier :string
#  name                :string
#  description         :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
module Nexo
  class Folder < ApplicationRecord
    belongs_to :integration, class_name: "Nexo::Integration"
    has_many :elements, class_name: "Nexo::Element"

    enum :protocol, calendar: 0

    validates :protocol, :name, presence: true

    # :nocov: TODO!, not yet being called
    def rules_match?(synchronizable)
      # TODO!: implement
      true
    end
    # :nocov:

    def find_element(synchronizable:)
      # FIXME: filter discarded
      ary = elements.where(synchronizable:).to_a

      if ary.count > 1
        raise Errors::MoreThanOneElementInFolderForSynchronizable
      end

      ary.first
    end

    def time_zone
      Rails.application.config.time_zone
    end
  end
end
