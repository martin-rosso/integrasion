module Nexo
  # Centralizes the creation of API service objects
  class ServiceBuilder
    @instance = new

    private_class_method :new

    def self.instance
      @instance
    end

    def build_protocol_service(folder)
      service_klass_name = "#{folder.integration.client.service}_#{folder.protocol}_service".camelcase
      build_service(service_klass_name, folder.integration)
    end

    def build_auth_service(integration)
      service_klass_name = "#{integration.client.service}_auth_service".camelcase
      build_service(service_klass_name, integration)
    end

    private

    def build_service(klass_name, integration)
      service_klass = Nexo.const_get(klass_name)

      service_klass.new(integration)
    end
  end
end
