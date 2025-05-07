module Nexo
  module ControllerHelper
    def nexo_integration_params(params)
      # When upgrading to Rails 8, use "expect"
      params.require(:integration).permit(:client_id, :name, scope: []).tap do |it|
        raise Errors::InvalidParamsError, "scope is required" unless it[:scope].present?
      end
    end
  end
end
