module Nexo
  class DeleteRemoteResourceJob < BaseJob
    limits_concurrency key: ->(element) { element.gid }, group: "RemoteResources"
    # FIXME: set polling interval 10 secs or so

    def perform(element)
      GoogleCalendar.remove(element.uuid)
    end
  end
end
