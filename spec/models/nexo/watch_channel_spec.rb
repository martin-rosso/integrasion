# == Schema Information
#
# Table name: nexo_watch_channels
#
#  id           :bigint           not null, primary key
#  folder_id    :bigint           not null
#  nwc_status   :integer          not null
#  touch_count  :integer          default(0), not null
#  touched_at   :datetime
#  payload      :string
#  expires_at   :datetime
#  id_channel   :string
#  id_resource  :string
#  secret_token :string
#  address      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require 'rails_helper'

module Nexo
  RSpec.describe WatchChannel, type: :model do
    pending "add some examples to (or delete) #{__FILE__}"
  end
end
