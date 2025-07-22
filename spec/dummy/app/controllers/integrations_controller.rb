class IntegrationsController < ActionController::Base
  include Nexo::ControllerHelper

  layout "application"

  before_action :set_integration, only: [ :show, :edit, :update, :destroy, :revoke_authorization, :perform_operation ]

  def index
    @integrations = Nexo::Integration.where(discarded_at: nil)
    @clients = Nexo::Client.where(nc_status: :authorized)
  end

  def new
    client = Nexo::Client.find(params[:client_id])
    @integration = Nexo::Integration.new(client_id: client.id)
  end

  def create
    @integration = Nexo::Integration.new(integration_params)
    @integration.user = Current.user
    @integration.save!

    redirect_to @integration
  end

  def edit
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
    @service = Nexo::GoogleAuthService.new(@integration)

    # Este get_credentials es necesario, si no, no se guarda el token
    #
    # Cuando vuelve del callback, guarda el token. Este token tendrá el scope
    # con *todos* los permisos efectivos que el usuario haya otorgado aunque el
    # client haya solicitado un subconjunto de los mismos
    @credentials = @service.get_credentials(request)
  end

  def perform_operation
    case params[:operation]
    when "create_test_folder"
      folder = Nexo::Folder.create!(
        integration: @integration,
        sync_direction: :sync_bidirectional,
        external_identifier: nil,
        nexo_protocol: :calendar,
        name: "Nexo Playground #{rand(99)}",
        description: "Automatically created calendar for"
      )
      DummyFolderRule.create!(folder:, sync_policy: :include, search_regex: ".*")
      Nexo::EventReceiver.new.folder_changed(folder)

      redirect_to @integration, notice: "Created folder: #{folder.name}"
    else
      redirect_to @integration, alert: "Unknown action"
    end
  end

  def revoke_authorization
    manager = Nexo::GoogleAuthService.new(@integration)
    manager.revoke_authorization!

    redirect_to @integration
  end

  def callback
    target_url = Nexo::GoogleAuthService.handle_auth_callback_deferred(request)
    # Vuelve a show
    redirect_to target_url
  end

  private

  def integration_params
    nexo_integration_params(params)
  end

  def set_integration
    @integration = Nexo::Integration.find(params[:id])
  end
end
