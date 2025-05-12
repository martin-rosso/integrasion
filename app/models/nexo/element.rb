# == Schema Information
#
# Table name: nexo_elements
#
#  id                  :integer          not null, primary key
#  folder_id           :integer          not null
#  synchronizable_id   :integer          not null
#  synchronizable_type :string           not null
#  flag_deletion       :boolean          not null
#  deletion_reason     :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
module Nexo
  class Element < ApplicationRecord
    belongs_to :folder, class_name: "Nexo::Folder"
    belongs_to :synchronizable, polymorphic: true
    has_many :element_versions, dependent: :destroy, class_name: "Nexo::ElementVersion"

    delegate :uuid, to: :synchronizable

    enum :deletion_reason, no_longer_included_in_folder: 0, synchronizable_destroyed: 1

    scope :conflicted, -> { where(conflicted: true) }

    def last_synced_sequence
      element_versions.pluck(:sequence).max || -1
    end

    def external_unsynced_change?
      last_external_unsynced_version.present?
    end

    def last_external_unsynced_version
      element_versions.where(sequence: nil).order(created_at: :desc).first
    end

    def mark_for_deletion!(deletion_reason)
      update!(flag_deletion: true, deletion_reason:)
    end

    def mark_as_conflicted!
      update!(conflicted: true)

      # TODO: log "Conflicted Element: #{element.gid}"
    end
  end
end
