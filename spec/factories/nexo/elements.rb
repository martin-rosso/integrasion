FactoryBot.define do
  factory :nexo_element, class: "Nexo::Element" do
    association :folder, factory: :nexo_folder
    association :synchronizable, factory: :event

    flagged_for_removal { false }
    uuid { Digest::MD5.hexdigest(Faker::Lorem.word) }

    trait :discarded do
      discarded_at { Faker::Date.backward }
    end

    trait :conflicted do
      conflicted { true }
    end

    trait :conflicted_indirectly do
      synchronizable { create(:event, :conflicted) }
    end

    trait :unsynced_local_change do
    end

    trait :unsynced_local_change_to_update do
      element_versions { build_list(:nexo_element_version, 1, sequence: synchronizable.sequence - 1) }
    end

    trait :unsynced_external_change do
      element_versions { build_list(:nexo_element_version, 1, sequence: nil, origin: "external") }
    end

    # Deprecated
    trait :with_versions do
      element_versions { build_list(:nexo_element_version, 1) }
    end

    trait :synced do
      element_versions { build_list(:nexo_element_version, 1, sequence: synchronizable.sequence) }
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
  end
end
