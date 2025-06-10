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
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ne_status           :integer          not null
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
    enum :ne_status, synced: 0, pending_external_sync: 1, pending_local_sync: 2, conflicted: 3

    scope :conflicted, -> { where(ne_status: :conflicted) }

    def policy_still_applies?
      # :nocov: TODO
      folder.policy_applies?(synchronizable)
      # :nocov:
    end

    def etag
      last_remote_version&.etag
    end

    def last_remote_version
      element_versions.where.not(etag: nil).order(:etag).last
    end

    def discarded?
      discarded_at.present?
    end
  end
end
