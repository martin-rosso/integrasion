# == Schema Information
#
# Table name: nexo_element_versions
#
#  id         :integer          not null, primary key
#  element_id :integer          not null
#  payload    :json
#  etag       :string
#  sequence   :integer
#  origin     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module Nexo
  class ElementVersion < ApplicationRecord
    belongs_to :element, class_name: "Nexo::Element"

    enum :origin, internal: 0, external: 1

    validates :payload, :etag, :origin, presence: true
  end
end
