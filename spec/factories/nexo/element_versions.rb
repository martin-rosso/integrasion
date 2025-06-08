# == Schema Information
#
# Table name: nexo_element_versions
#
#  id         :bigint           not null, primary key
#  element_id :bigint           not null
#  payload    :string
#  etag       :string
#  sequence   :integer
#  origin     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  nev_status :integer          not null
#
def read_payload_json(name)
  JSON.parse(File.read(Nexo::Engine.root.join("spec/factories/nexo/element_version_payloads", "#{name}.json")))
end

FactoryBot.define do
  factory :nexo_element_version, class: "Nexo::ElementVersion" do
    association :element, factory: :nexo_element
    origin { %i[internal external].sample }
    payload { read_payload_json("google_calendar_event_with_time") }

    trait :with_time do
      payload { read_payload_json("google_calendar_event_with_time") }
    end

    trait :all_day do
      payload { read_payload_json("google_calendar_event_all_day") }
    end

    trait :synced do
      etag { "asd" }
      nev_status { :synced }
      add_attribute(:sequence) { rand(0..10) }
    end

    trait :unsynced_local_change do
      nev_status { :pending_sync }
      origin { "internal" }
      add_attribute(:sequence) { rand(0..10) }
      etag { nil }
    end

    trait :element_previously_synced do
      element { create :nexo_element, uuid: Digest::MD5.hexdigest(Faker::Lorem.word) }
    end

    trait :unsynced_external_change do
      add_attribute(:sequence) { nil }
      nev_status { :pending_sync }
      origin { "external" }
    end

    after(:create) do |element_version, context|
      element_version.element.update_ne_status!
    end
  end
end
