# == Schema Information
#
# Table name: integrasion_third_party_clients
#
#  id                        :integer          not null, primary key
#  service                   :integer
#  secret                    :json
#  tcp_status                :integer
#  brand_name                :integer
#  user_integrations_allowed :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
module Integrasion
  AVAILABLE_SCOPES = {
    google_calendar: [ "Google::Apis::CalendarV3::AUTH_CALENDAR_APP_CREATED" ]
  }

  class ThirdPartyClient < ApplicationRecord
    encrypts :secret

    enum :service, google_calendar: 0
    enum :tcp_status, authorized: 0, disabled: 1, expired: 2

    validates :service, :available_scopes, :user_integrations_allowed,
              :tcp_status, :secret, presence: true
  end
end
