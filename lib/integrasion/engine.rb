module Integrasion
  class Engine < ::Rails::Engine
    isolate_namespace Integrasion

    initializer 'configurar_generators' do
      config.generators do |g|
        g.test_framework :rspec
        g.orm :active_record
      end
    end
  end
end
