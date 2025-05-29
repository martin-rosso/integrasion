module Nexo
  class DeleteRemoteResourceJob < BaseJob
    include ApiClients

    def perform(element)
      ServiceBuilder.instance.build_protocol_service(element.folder).remove(element)
      # FIXME!: mark as deleted, or something
    end
  end
end
