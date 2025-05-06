require "googleauth"
require "googleauth/stores/file_token_store"
require "google-apis-calendar_v3"

module Integrasion
  class GoogleService
    def initialize(third_party_integration, request = nil)
      @third_party_integration = third_party_integration
      @user_id = third_party_integration&.third_party_id_user
      @third_party_client = third_party_integration&.third_party_client
      @request = request
    end

    SCOPE = [ Google::Apis::CalendarV3::AUTH_CALENDAR_APP_CREATED ].freeze

    def authorizer
      # FIXME: load from rails credentials if present
      hsh = @third_party_client.secret
      client_id = Google::Auth::ClientId.from_hash hsh

      token_store = Integrasion::ActiveRecordGoogleTokenStore.new(@third_party_integration)
      Google::Auth::WebUserAuthorizer.new client_id, SCOPE, token_store, "/u/google/callback"
    end

    def handle_auth_callback_deferred(request)
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      # @cuenta_email.update_attributes(status: :autorizada) if @cuenta_email.check_autorizacion(nil)

      target_url
    end

    # @request es opcional. Debe estar presente en la autorización
    # (cuando google_auth/callback redirige a google_auth/authorize
    # luego
    def get_credentials
      return unless @user_id.present?

      authorizer.get_credentials @user_id, @request
    end

    def get_authorization_url(request)
      authorizer.get_authorization_url(request: request)
    end
  end
end
