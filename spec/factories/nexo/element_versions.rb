FactoryBot.define do
  factory :nexo_element_version, class: "Nexo::ElementVersion" do
    association :element, factory: :nexo_element
    origin { "internal" }
    payload { "bla" }
    etag { "asd" }
    add_attribute(:sequence) { rand(0..10) }
  end
end
