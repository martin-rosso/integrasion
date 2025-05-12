# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :integer          not null, primary key
#  integration_id      :integer          not null
#  protocol            :integer          not null
#  external_identifier :string
#  name                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

module Nexo
  RSpec.describe Folder, type: :model do
    pending "add some examples to (or delete) #{__FILE__}"
  end
end
