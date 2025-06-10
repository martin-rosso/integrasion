module Nexo
  class ImportRemoteElementVersion
    class VersionSuperseded < Errors::Error; end

    def perform(element_version)
      validate_element_state!(element_version)

      ElementService.new(element_version:).update_synchronizable!
    rescue VersionSuperseded
      Nexo.logger.info { "ImportRemoteElementVersion: version superseded" }
    end

    private

    def validate_element_state!(element_version)
      element = element_version.element

      raise "element version must be external" if element_version.internal?
      raise "etag must be present" if element_version.etag.blank?

      # NOTE: this is actually very coupled to the way Google manages etag as a
      # sequential number, if a new protocol or service is added in the future
      # and it doesnt manage it that way, it would have to be delegated to the
      # protocol service
      if element.element_versions.where(nev_status: :synced)
                .where("etag > ?", element_version.etag).any?

        ElementService.new(element_version:).update_element_version!(nev_status: :superseded)

        raise VersionSuperseded
      end

      if element.conflicted?
        raise Errors::ElementConflicted
      end

      # :nocov: borderline
      if element.synchronizable.blank?
        raise Errors::SynchronizableNotFound
      end

      if element.discarded?
        raise Errors::ElementDiscarded
      end

      if element.synchronizable.conflicted?
        raise Errors::SynchronizableConflicted
      end

      if element.synchronizable.sequence.nil?
        raise Errors::SynchronizableSequenceIsNull
      end
      # :nocov:
    end
  end
end
