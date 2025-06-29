# == Schema Information
#
# Table name: nexo_integrations
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  client_id    :bigint           not null
#  name         :string
#  scope        :string
#  expires_at   :datetime
#  discarded_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
module Nexo
  class Integration < ApplicationRecord
    serialize :scope, coder: JSON
    belongs_to :user
    belongs_to :client, class_name: "Nexo::Client"
    has_many :tokens, class_name: "Nexo::Token"
    has_many :folders, class_name: "Nexo::Folder"

    before_validation do
      self.scope = scope.select(&:present?)
    end

    validates :scope, presence: true

    def external_api_scope
      if scope.blank?
        # :nocov: borderline
        raise "scope must be present"
        # :nocov:
      end

      scope.map { |permission| client.service_scopes[permission.to_sym] }
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

    def token?
      token_status.in? [ :active_token, :expired_token ]
    end

    def credentials
      service = ServiceBuilder.instance.build_auth_service(self)
      @credentials ||= service.get_credentials
    end
  end
end
