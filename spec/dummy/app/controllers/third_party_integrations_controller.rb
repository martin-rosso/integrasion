class ThirdPartyIntegrationsController < ApplicationController
  before_action :set_third_party_integration, only: [ :show, :destroy ]

  def new
    @client = Integrasion::ThirdPartyClient.find(params[:client_id])
    @available_scopes = Integrasion::AVAILABLE_SCOPES[@client.service.to_sym].keys
    @third_party_integration =
      Integrasion::ThirdPartyIntegration.new(integrasion_third_party_client_id: @client.id)
  end

  def create
    @third_party_integration = Integrasion::ThirdPartyIntegration.new(third_party_integration_params)
    @third_party_integration.user = Current.user
    @third_party_integration.tpi_status = :pending
    @third_party_integration.save!

    redirect_to @third_party_integration
  end

  def destroy
    @third_party_integration.destroy!

    redirect_to third_party_integrations_path
  end

  def show
    # if @cuenta_email.check_autorizacion(request)
    #   # @cuenta_email.update_attributes(status: :autorizada)
    # else
    #   # @cuenta_email.update_attributes(status: :no_autorizada)

    # end
    #
    # FIXME: no debería pasar el user email sino el GoogleApisAuthorization#email
    # y además no es necesario pasarlo en el initialize sino directamente en el get_credentials
    manager = Integrasion::GoogleService.new(@third_party_integration, request)


    # Este get_credentiales es necesario, si no, no se guarda el token
    @credentials = manager.get_credentials
    if @credentials.nil?
      @url = manager.get_authorization_url(request)
    else
    end
  end

  def callback
    manager = Integrasion::GoogleService.new(nil)
    target_url = manager.handle_auth_callback_deferred(request)
    redirect_to target_url
    # Vuelve a show
    # Esto es necesario, y que allí se llame a get_credentials
    # Y si llamo acá mismo a get_credentials?
  end

  private

  def third_party_integration_params
    params.require(:third_party_integration).permit(:integrasion_third_party_client_id, :third_party_id_user, scope: [])
  end

  def set_third_party_integration
    @third_party_integration = Integrasion::ThirdPartyIntegration.find(params[:id])
  end
end
