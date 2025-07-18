module Nexo
  class ImportRemoteElementVersion
    class VersionSuperseded < Errors::Error; end
    class ImportRemoteVersionFailed < Errors::Error; end

    def perform(element_version)
      validate_element_state!(element_version)

      ElementService.new(element_version:).update_synchronizable!
    rescue ImportRemoteVersionFailed => e
      Nexo.logger.warn(e.inspect)
    rescue VersionSuperseded
      Nexo.logger.info("ImportRemoteElementVersion: version superseded")
    end

    private

    def validate_element_state!(element_version)
      element = element_version.element

      raise Nexo::Errors::Error, "element version must be external" if element_version.internal?
      raise Nexo::Errors::Error, "etag must be present" if element_version.etag.blank?

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
        raise ImportRemoteVersionFailed, "element conflicted"
      end

      # if element.synchronizable.blank?
      #   # TODO!: this could be that an external element was restored. i.e.:
      #   # google calendar event cancelled and restored.
      #   # this should be handled in some way, maybe configurable per folder
      #   # options are:
      #   #   - ignore the element
      #   #   - create synchronizable as if it were new
      #   #   - discard/undiscard, for this the synchronizable should have been
      #   #     deleted
      #   raise ImportRemoteVersionFailed, "synchronizable not found"
      # end

      # :nocov: borderline
      if element.discarded?
        # TODO!: this could be that an external element was restored. i.e.:
        #   Event excluded from folder and then restored from Google Calendar
        raise ImportRemoteVersionFailed, "element discarded"
      end

      if element.synchronizable.present?
        if element.synchronizable.conflicted?
          raise ImportRemoteVersionFailed, "synchronizable conflicted"
        end

        if element.synchronizable.sequence.nil?
          raise ImportRemoteVersionFailed, "synchronizable sequence is null"
        end
      end
      # :nocov:
    end
  end
end
