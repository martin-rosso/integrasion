FactoryBot.define do
  factory :nexo_folder, class: "Nexo::Folder" do
    association :integration, factory: :nexo_integration
    name { "Default folder" }
    nexo_protocol { "calendar" }
    description { Faker::Lorem.sentence }
    external_identifier { rand(999..9999).to_s }
  end
end
