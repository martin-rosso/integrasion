class IntegrationsController < ApplicationController
  before_action :set_integration, only: [ :show, :edit, :update, :destroy, :revoke_authorization ]

  def index
    @integrations = Integrasion::Integration.where(discarded_at: nil)
  end

  def new
    @client = Integrasion::Client.find(params[:client_id])
    @available_scopes = Integrasion::AVAILABLE_SCOPES[@client.service.to_sym].keys
    @integration =
      Integrasion::Integration.new(client_id: @client.id)
  end

  def create
    @integration = Integrasion::Integration.new(integration_params)
    @integration.user = Current.user
    @integration.save!

    redirect_to @integration
  end

  def edit
    @client = @integration.client
    @available_scopes = Integrasion::AVAILABLE_SCOPES[@client.service.to_sym].keys
  end

  def update
    @integration.update!(integration_params)

    redirect_to integrations_path
  end

  def destroy
    @integration.update!(discarded_at: Time.current)

    redirect_to integrations_path
  end

  def show
    manager = Integrasion::GoogleService.new(@integration)

    @tokens = Integrasion::Token.where(integration: @integration)

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
    manager = Integrasion::GoogleService.new(@integration)
    manager.revoke_authorization!

    redirect_to @integration
  end

  def callback
    target_url = Integrasion::GoogleService.handle_auth_callback_deferred(request)
    # Vuelve a show
    redirect_to target_url
  end

  private

  def integration_params
    params.require(:integration).permit(:client_id, :name, scope: [])
  end

  def set_integration
    @integration = Integrasion::Integration.find(params[:id])
  end
end
