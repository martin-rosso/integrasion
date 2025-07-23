begin
  FactoryBot.define do
    factory :user do
      email { Faker::Internet.email }
      password { Faker::Lorem.word }
    end
  end
rescue FactoryBot::DuplicateDefinitionError => e
  # it may be defined by the main app, anyway this is not bundled with the gem
  puts e.inspect
end
