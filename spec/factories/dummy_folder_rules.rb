FactoryBot.define do
  factory :dummy_folder_rule do
    folder factory: :nexo_folder

    trait :match_all do
      sync_policy { "include" }
      search_regex { ".*" }
    end
  end
end
