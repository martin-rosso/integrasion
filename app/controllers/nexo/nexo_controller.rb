module Nexo
  class NexoController < Nexo.admin_controller_parent_class
    layout "nexo"

    rescue_from StandardError do |e|
      @exception = e

      render "layouts/error"
    end
  end
end
