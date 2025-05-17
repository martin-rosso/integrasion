module Nexo
  # @!visibility private
  class Engine < ::Rails::Engine
    isolate_namespace Nexo

    initializer "nexo.collapse_dirs" do
      dir = "#{root}/app/lib/nexo/calendar"
      Rails.autoloaders.main.collapse(dir)
    end

    initializer "configurar_generators" do
      config.generators do |g|
        g.test_framework :rspec
        g.orm :active_record
      end
    end
  end
end
