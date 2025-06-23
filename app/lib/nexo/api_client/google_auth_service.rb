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

      # user revoked access
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
      # TODO: handle this
      # :nocov: TODO
      Nexo::ActiveRecordGoogleTokenStore.new.delete(@integration)
      e.class.to_s
      # :nocov:
    end

    def revoke_authorization!
      authorizer.revoke_authorization(@integration)
    end

    # @param [Rack::Request] request
    #
    # Debe estar presente en la autorización (cuando google callback redirige
    # al show)
    #
    # Guarda el Token
    # Si el client tiene más permisos que los que el user solicitó
    def get_credentials(request = nil)
      # :nocov: tricky
      if request.present? && request.session["code_verifier"].present?
        authorizer.code_verifier = request.session["code_verifier"]
      end
      # :nocov:

      authorizer.get_credentials(@integration, request).tap do |credentials|
        if credentials.nil? && request.present? && !request.session["code_verifier"].present?
          Nexo.logger.warn("Request has no code_verifier")
        end
      end
    rescue Signet::AuthorizationError
      # TODO: log
    end

    def get_authorization_url(request, login_hint: nil)
      request.session["code_verifier"] ||= Google::Auth::WebUserAuthorizer.generate_code_verifier
      authorizer.code_verifier = request.session["code_verifier"]
      # authorizer.get_authorization_url(request:)
      authorizer.get_authorization_url(request:, login_hint:)
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
