# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :bigint           not null, primary key
#  integration_id      :bigint           not null
#  nexo_protocol       :integer          not null
#  external_identifier :string
#  name                :string
#  description         :string
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
FactoryBot.define do
  factory :nexo_folder, class: "Nexo::Folder" do
    association :integration, factory: :nexo_integration
    name { "Default folder" }
    nexo_protocol { "calendar" }
    description { Faker::Lorem.sentence }
    external_identifier { rand(999..9999).to_s }

    trait :discarded do
      discarded_at { Faker::Date.backward }
    end

    trait :with_rule_matching_all do
      after(:create) do |folder, context|
        create(:dummy_folder_rule, :match_all, folder:)
      end
    end
  end
end
