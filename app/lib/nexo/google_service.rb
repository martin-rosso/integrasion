require "googleauth"
require "googleauth/stores/file_token_store"
require "google-apis-calendar_v3"
require "google-apis-oauth2_v2"

module Nexo
  # This is actually an OAuth 2.0 flow, and that logic should be extracted to
  # a generic OAuth2Service
  class GoogleAuthService
    class << self
      def handle_auth_callback_deferred(request)
        target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)

        target_url
      end
    end

    def initialize(integration)
      @integration = integration
    end

    EXCEPTIONS = [
      Signet::AuthorizationError,

      # El usuario revocó los permisos
      Google::Apis::ClientError,

      Google::Apis::AuthorizationError
    ]

    def token_info
      service = Google::Apis::Oauth2V2::Oauth2Service.new
      credentials = get_credentials
      if credentials.present?
        service.authorization = credentials

        # Si el token expiró o le restan pocos segundos para expirar, se
        # renovará el token.
        service.tokeninfo
      end
    rescue *EXCEPTIONS => e
      # FIXME: handle this
      # :nocov:
      Nexo::ActiveRecordGoogleTokenStore.new.delete(@integration)
      e.class.to_s
      # :nocov:
    end

    def revoke_authorization!
      authorizer.revoke_authorization(@integration)
    end

    # @request es opcional.
    # Debe estar presente en la autorización (cuando google callback redirige
    # al show)
    #
    # Guarda el Token
    # Si el client tiene más permisos que los que el user solicitó
    def get_credentials(request = nil)
      if request.present? && request.session["code_verifier"].present?
        authorizer.code_verifier = request.session["code_verifier"]
      end
      authorizer.get_credentials @integration, request
    rescue Signet::AuthorizationError
      # FIXME: log
    end

    def get_authorization_url(request)
      request.session["code_verifier"] ||= Google::Auth::WebUserAuthorizer.generate_code_verifier
      authorizer.code_verifier = request.session["code_verifier"]
      authorizer.get_authorization_url(request:)
      # authorizer.get_authorization_url(request:, login_hint: "bla@gmail.com")
    end

    private

    def authorizer
      client = @integration.client
      client_id = Google::Auth::ClientId.from_hash(client.secret)

      token_store = Nexo::ActiveRecordGoogleTokenStore.new

      @authorizer ||=
        Google::Auth::WebUserAuthorizer.new(
          client_id, @integration.external_api_scope, token_store, "/u/google/callback")
    end
  end
end
