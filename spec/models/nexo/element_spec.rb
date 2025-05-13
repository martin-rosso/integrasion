# == Schema Information
#
# Table name: nexo_elements
#
#  id                  :integer          not null, primary key
#  folder_id           :integer          not null
#  synchronizable_id   :integer          not null
#  synchronizable_type :string           not null
#  flag_deletion       :boolean          not null
#  deletion_reason     :integer
#  conflicted          :boolean          default(FALSE), not null
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

module Nexo
  RSpec.describe Element, type: :model do
    pending "add some examples to (or delete) #{__FILE__}"
  end
end
