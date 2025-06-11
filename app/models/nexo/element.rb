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

    def update_ne_status!
      external_change = element_versions.where(origin: :external, nev_status: :pending_sync).any?
      local_change = element_versions.where(origin: :internal, nev_status: :pending_sync).any?

      self.ne_status =
        if external_change && local_change
          :conflicted
        elsif external_change
          :pending_external_sync
        elsif local_change
          :pending_local_sync
        else
          :synced
        end

      save!
    end

    def etag
      last_remote_version&.etag
    end

    def last_remote_version
      element_versions.where.not(etag: nil).order(:etag).last
    end

    def resolve_conflict!
      unless conflicted?
        raise "element not conflicted"
      end

      # both lock on Element and start a transaction
      with_lock do
        # FIXME: ElementVersions must be created within a lock to the element

        external_change = element_versions.where(origin: :external, nev_status: :pending_sync).order(:etag).last
        local_change = element_versions.where(origin: :internal, nev_status: :pending_sync).order(:sequence).last
        last_synced = element_versions.where(nev_status: :synced).order(:sequence).last

        if local_change.sequence < last_synced.sequence
          raise "there a newer synced sequence"
        end

        if external_change.etag < last_synced.etag
          raise "there a newer synced etag"
        end

        Nexo.logger.debug { "resolving conflict" }
        remote_update = Time.zone.parse(external_change.payload["updated"])
        local_update = synchronizable.updated_at
        Nexo.logger.debug { "Remote updated at: #{remote_update}. Local updated at #{local_update}" }
        if remote_update > local_update
          Nexo.logger.debug { "Remote wins, ignoring local change" }
          synchronizable.update_from!(external_change)
          win_version = external_change
        else
          Nexo.logger.debug { "Local wins, discarding remote changes" }
          UpdateRemoteResourceJob.perform_later(local_change)
          win_version = local_change
        end

        element_versions.where(nev_status: :pending_sync)
                        .where.not(id: win_version.id)
                        .update_all(nev_status: :ignored_in_conflict)

        update_ne_status!
      end
    end

    def flag_for_removal!(removal_reason)
      update!(flagged_for_removal: true, removal_reason:)
    end

    def discarded?
      discarded_at.present?
    end

    def discard!
      update!(discarded_at: Time.current)
    end
  end
end
