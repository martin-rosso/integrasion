# == Schema Information
#
# Table name: integrasion_third_party_integrations
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  third_party_client_id :integer          not null
#  name                  :string
#  scope                 :string
#  expires_at            :datetime
#  discarded_at          :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
module Integrasion
  class ThirdPartyIntegration < ApplicationRecord
    include Discard::Model if defined? Discard::Model
    include Hashid::Rails if defined? Hashid::Rails

    serialize :scope, coder: JSON
    belongs_to :user
    belongs_to :third_party_client, class_name: "Integrasion::ThirdPartyClient"
    has_many :third_party_tokens, class_name: "Integrasion::ThirdPartyToken"

    validates :scope, presence: true

    def external_api_scope
      scope.map { |permission| third_party_client.external_api_scopes[permission.to_sym] }
    end

    def credentials
      manager = Integrasion::GoogleService.new(self)
      @credentials ||= manager.get_credentials
    end

    def expires_in
      return unless credentials.present?

      (credentials.expires_at - Time.current).to_i
    end

    def token_status
      if credentials.present?
        if credentials.expires_at > Time.current
          :active_token
        else
          :expired_token
        end
      else
        :no_token
      end
    end
  end
end
