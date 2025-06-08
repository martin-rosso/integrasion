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
FactoryBot.define do
  factory :nexo_element, class: "Nexo::Element" do
    association :folder, factory: :nexo_folder
    association :synchronizable, factory: :event

    flagged_for_removal { false }
    # uuid { Digest::MD5.hexdigest(Faker::Lorem.word) }

    # To fulfill the not null constraint. Anyway this will be updated by the
    # after create callback
    ne_status { :synced }

    trait :discarded do
      discarded_at { Faker::Date.backward }
    end

    trait :conflicted do
      element_versions {
        [
          build(:nexo_element_version, :unsynced_local_change),
          build(:nexo_element_version, :unsynced_external_change)
        ]
      }
    end

    trait :conflicted_indirectly do
      synchronizable { create(:event, :conflicted) }
    end

    trait :unsynced_local_change do
    end

    trait :unsynced_local_change_to_update do
      element_versions {
        [
          build(:nexo_element_version, :synced, sequence: synchronizable.sequence - 1),
          build(:nexo_element_version, :unsynced_local_change)
        ]
      }
    end

    trait :unsynced_external_change do
      element_versions {
        [
          build(:nexo_element_version, sequence: synchronizable.sequence),
          build(:nexo_element_version, :unsynced_external_change)
        ]
      }
    end

    trait :synced do
      element_versions { build_list(:nexo_element_version, 1, :synced, sequence: synchronizable.sequence) }
    end

    trait :flagged_for_removal do
      flagged_for_removal { true }
      removal_reason { "synchronizable_destroyed" }
    end

    trait :with_ghost_synchronizable do
      after(:create) do |element, context|
        element.update_columns(synchronizable_id: rand(999999))
      end
    end

    after(:create) do |element, context|
      element.update_ne_status!
    end
  end
end
