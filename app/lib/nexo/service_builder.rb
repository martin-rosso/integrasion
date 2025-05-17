module Nexo
  class ServiceBuilder
    @instance = new

    private_class_method :new

    def self.instance
      @instance
    end

    # @todo FIXME: find a better name
    def build_remote_service(folder)
      service_klass_name = "#{folder.integration.client.service}_#{folder.protocol}_service".camelcase
      service_klass = Nexo.const_get(service_klass_name)

      if service_klass.nil?
        # :nocov: borderline
        raise "service not found: #{service_klass_name}"
        # :nocov:
      end

      service_klass.new(folder.integration)
    end

    def build_auth_service(integration)
      GoogleAuthService.new(integration)
    end
  end
end
