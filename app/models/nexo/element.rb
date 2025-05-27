# == Schema Information
#
# Table name: nexo_elements
#
#  id                  :bigint           not null, primary key
#  folder_id           :bigint           not null
#  synchronizable_id   :integer          not null
#  synchronizable_type :string           not null
#  uuid                :string
#  flagged_for_removal :boolean          not null
#  removal_reason      :integer
#  conflicted          :boolean          default(FALSE), not null
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
module Nexo
  class Element < ApplicationRecord
    belongs_to :folder, class_name: "Nexo::Folder"
    belongs_to :synchronizable, polymorphic: true
    has_many :element_versions, dependent: :destroy, class_name: "Nexo::ElementVersion"

    after_initialize do
      # TODO: https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute
      self.flagged_for_removal = false if flagged_for_removal.nil?
    end

    scope :kept, -> { where(discarded_at: nil) }

    enum :removal_reason, no_longer_included_in_folder: 0, synchronizable_destroyed: 1

    scope :conflicted, -> { where(conflicted: true) }

    def policy_still_match?
      folder.policy_match?(synchronizable)
    end

    def last_synced_sequence
      element_versions.pluck(:sequence).max || -1
    end

    def external_unsynced_change?
      last_external_unsynced_version.present?
    end

    def last_external_unsynced_version
      element_versions.where(sequence: nil).order(created_at: :desc).first
    end

    def flag_for_deletion!(removal_reason)
      update!(flagged_for_removal: true, removal_reason:)
    end

    def flagged_for_deletion?
      flagged_for_removal?
    end

    # :nocov: TODO, not yet being called
    def flag_as_conflicted!
      update!(conflicted: true)

      # TODO: log "Conflicted Element: #{element.to_gid}"
    end
    # :nocov:

    def discarded?
      discarded_at.present?
    end

    def discard!
      update!(discarded_at: Time.current)
    end
  end
end
