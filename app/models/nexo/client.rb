# == Schema Information
#
# Table name: nexo_clients
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
require "google-apis-calendar_v3"
require "google-apis-oauth2_v2"

module Nexo
  AVAILABLE_SCOPES = {
    google: {
      # auth_email: Google::Apis::Oauth2V2::AUTH_USERINFO_EMAIL,
      auth_calendar_app_created: Google::Apis::CalendarV3::AUTH_CALENDAR_APP_CREATED,
      auth_calendar_calendarlist: Google::Apis::CalendarV3::AUTH_CALENDAR_CALENDARLIST
    }
  }

  class Client < ApplicationRecord
    encrypts :secret

    enum :service, google: 0
    enum :tcp_status, authorized: 0, disabled: 1, expired: 2

    validates :service, :user_integrations_allowed,
              :tcp_status, :secret, presence: true

    def to_s
      service.titleize
    end

    def external_api_scopes
      AVAILABLE_SCOPES[service.to_sym]
    end
  end
end
