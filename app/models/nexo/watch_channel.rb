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
module Nexo
  class WatchChannel < ApplicationRecord
    belongs_to :folder

    serialize :payload, coder: JSON

    # This is actually the same for all channels, and its
    # Nexo.google_webhook_token, its redundant by now, but eventually
    # there could be a specific token for each channel or folder.
    encrypts :webhook_token

    enum :nwc_status,
      watching: 0,
      stopped: 1,
      expired: 2
  end
end
