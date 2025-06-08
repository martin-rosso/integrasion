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
FactoryBot.define do
  factory :nexo_element_version, class: "Nexo::ElementVersion" do
    association :element, factory: :nexo_element
    origin { "internal" }
    payload { "bla" }
    etag { "asd" }
    add_attribute(:sequence) { rand(0..10) }
  end
end
