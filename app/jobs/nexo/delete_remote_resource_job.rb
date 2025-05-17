module Nexo
  class DeleteRemoteResourceJob < BaseJob
    # TODO: limit by integration, instead of element
    limits_concurrency key: ->(element) { element.gid }, group: "IntegrationApiCall"
    # TODO: set polling interval 10 secs or so

    def perform(element)
      ServiceBuilder.instance.build_remote_service(element.folder).remove(element)
    end
  end
end
