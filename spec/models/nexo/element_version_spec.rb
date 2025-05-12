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
require 'rails_helper'

module Nexo
  RSpec.describe ElementVersion, type: :model do
    pending "add some examples to (or delete) #{__FILE__}"
  end
end
