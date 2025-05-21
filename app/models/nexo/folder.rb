# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :bigint           not null, primary key
#  integration_id      :bigint           not null
#  protocol            :integer          not null
#  external_identifier :string
#  name                :string
#  description         :string
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
module Nexo
  class Folder < ApplicationRecord
    belongs_to :integration, class_name: "Nexo::Integration"
    has_many :elements, class_name: "Nexo::Element"

    if respond_to?(:enumerize)
      enumerize :protocol, in: { calendar: 0, dummy_calendar: 1 }
    else
      enum :protocol, calendar: 0, dummy_calendar: 1
    end

    scope :kept, -> { where(discarded_at: nil) }

    validates :protocol, :name, presence: true

    # TODO!: find better name
    # maybe policy_applies?
    def policy_match?(synchronizable)
      PolicyService.instance.match?(self, synchronizable)
    end

    def find_element(synchronizable:)
      ary = elements.where(synchronizable:, discarded_at: nil).to_a

      if ary.count > 1
        raise Errors::MoreThanOneElementInFolderForSynchronizable
      end

      ary.first
    end

    def time_zone
      Rails.application.config.time_zone
    end

    def discarded?
      discarded_at.present?
    end

    def discard!
      update!(discarded_at: Time.current)
    end
  end
end
