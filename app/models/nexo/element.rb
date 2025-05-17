# == Schema Information
#
# Table name: nexo_elements
#
#  id                  :integer          not null, primary key
#  folder_id           :integer          not null
#  synchronizable_id   :integer          not null
#  synchronizable_type :string           not null
#  uuid                :string
#  flag_deletion       :boolean          not null
#  deletion_reason     :integer
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
      self.flag_deletion = false if flag_deletion.nil?
    end

    enum :deletion_reason, no_longer_included_in_folder: 0, synchronizable_destroyed: 1

    scope :conflicted, -> { where(conflicted: true) }

    def rules_still_match?
      # :nocov: FIXME
      true
      # :nocov:
      # folder.rules_match?(synchronizable)
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

    def flag_for_deletion!(deletion_reason)
      update!(flag_deletion: true, deletion_reason:)
    end

    def flagged_for_deletion?
      flag_deletion?
    end

    # :nocov: TODO, not yet being called
    def flag_as_conflicted!
      update!(conflicted: true)

      # TODO: log "Conflicted Element: #{element.gid}"
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
