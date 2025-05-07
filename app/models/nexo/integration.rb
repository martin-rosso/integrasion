# == Schema Information
#
# Table name: nexo_integrations
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  client_id    :integer          not null
#  name         :string
#  scope        :string
#  expires_at   :datetime
#  discarded_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
module Nexo
  class Integration < ApplicationRecord
    include Discard::Model if defined? Discard::Model
    include Hashid::Rails if defined? Hashid::Rails

    serialize :scope, coder: JSON
    belongs_to :user
    belongs_to :client, class_name: "Nexo::Client"
    has_many :tokens, class_name: "Nexo::Token"

    validates :scope, presence: true

    def external_api_scope
      scope.map { |permission| client.external_api_scopes[permission.to_sym] }
    end

    def credentials
      service = Nexo::GoogleService.new(self)
      @credentials ||= service.get_credentials
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
