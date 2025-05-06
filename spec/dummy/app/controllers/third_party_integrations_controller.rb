class ThirdPartyIntegrationsController < ApplicationController
  before_action :set_third_party_integration, only: [ :show, :edit, :update, :destroy, :revoke_authorization ]

  def index
    @third_party_integrations = Integrasion::ThirdPartyIntegration.where(discarded_at: nil)
  end

  def new
    @client = Integrasion::ThirdPartyClient.find(params[:client_id])
    @available_scopes = Integrasion::AVAILABLE_SCOPES[@client.service.to_sym].keys
    @third_party_integration =
      Integrasion::ThirdPartyIntegration.new(third_party_client_id: @client.id)
  end

  def create
    @third_party_integration = Integrasion::ThirdPartyIntegration.new(third_party_integration_params)
    @third_party_integration.user = Current.user
    @third_party_integration.save!

    redirect_to @third_party_integration
  end

  def edit
    @client = @third_party_integration.third_party_client
    @available_scopes = Integrasion::AVAILABLE_SCOPES[@client.service.to_sym].keys
  end

  def update
    @third_party_integration.update!(third_party_integration_params)

    redirect_to third_party_integrations_path
  end

  def destroy
    @third_party_integration.update!(discarded_at: Time.current)

    redirect_to third_party_integrations_path
  end

  def show
    manager = Integrasion::GoogleService.new(@third_party_integration)

    @tokens = Integrasion::ThirdPartyToken.where(third_party_integration: @third_party_integration)

    if params[:check_token]
      @token_info = manager.token_info
    end

    # Este get_credentials es necesario, si no, no se guarda el token
    @credentials = manager.get_credentials(request)
    if @credentials.nil?
      @url = manager.get_authorization_url(request)
    end
  end

  def revoke_authorization
    manager = Integrasion::GoogleService.new(@third_party_integration)
    manager.revoke_authorization!

    redirect_to @third_party_integration
  end

  def callback
    target_url = Integrasion::GoogleService.handle_auth_callback_deferred(request)
    # Vuelve a show
    redirect_to target_url
  end

  private

  def third_party_integration_params
    params.require(:third_party_integration).permit(:third_party_client_id, :name, scope: [])
  end

  def set_third_party_integration
    @third_party_integration = Integrasion::ThirdPartyIntegration.find(params[:id])
  end
end
