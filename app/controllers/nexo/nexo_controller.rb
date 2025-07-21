module Nexo
  class NexoController < Nexo.admin_controller_parent_class
    layout "nexo"

    around_action :set_locale

    def set_locale
      # To show kaminari in english
      I18n.with_locale(:en) do
        yield
      end
    end

    rescue_from StandardError do |e|
      @exception = e

      render "layouts/error"
    end
  end
end
