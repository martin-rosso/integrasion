FactoryBot.define do
  factory :event do
    date_from { Faker::Date.forward }
    date_to { date_from ? date_from + 1.day : Faker::Date.forward }
    time_from { Faker::Time.forward }
    time_to { time_from ? time_from + 30.minutes : Faker::Time.forward }
    summary { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    add_attribute(:sequence) { rand(0..10) }

    trait :with_nil_sequence do
      add_attribute(:sequence) { nil }
    end

    trait :not_yet_synced do
    end

    trait :conflicted do
      nexo_elements { create_list(:nexo_element, 1, :conflicted) }
    end

    trait :with_elements do
      nexo_elements { build_list(:nexo_element, 2) }
    end

    trait :all_day_event do
      time_from { nil }
      time_to { nil }
    end
  end
end
