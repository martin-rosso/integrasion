module Nexo
  class UpdateRemoteResourceJob < BaseJob
    include ApiClients

    # https://github.com/rails/solid_queue?tab=readme-ov-file#jobs-and-transactional-integrity
    self.enqueue_after_transaction_commit = true

    attr_reader :element, :element_version

    # @raise Google::Apis::ClientError
    # @raise [ActiveRecord::RecordNotUnique] on ElementVersion update
    # @raise [Errno::ENETUNREACH]
    #   - (Network is unreachable - Network is unreachable - connect(2) for "www.googleapis.com"
    # @raise [Signet::AuthorizationError]
    #   - Unexpected error: #<Faraday::ConnectionFailed
    #       wrapped=#<Socket::ResolutionError: Failed to open TCP connection to
    #       oauth2.googleapis.com:443 (getaddrinfo: Name or service not known)>>"
    def perform(element_version)
      @element_version = element_version
      @element = element_version.element

      validate_element_state!

      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      response =
        if element.uuid.present?
          remote_service.update(element)
        else
          remote_service.insert(element).tap do |response|
            element.update(uuid: response.id)
          end
        end

      update_element_version(response)
    rescue Errors::ConflictingRemoteElementChange => e
      Nexo.logger.warn <<~STR
        ConflictingRemoteElementChange for #{element.to_gid}

        Enqueuing FetchRemoteResourceJob, which should lead to conflicted element
      STR
      FetchRemoteResourceJob.perform_later(element)
    end

    private

    def validate_element_state!
      if element.element_versions.where(nev_status: :synced)
                .where("sequence > ?", element_version.sequence).any?

        element_version.update(nev_status: :superseded)

        raise Errors::Error, "version superseded"
      end

      if element.synchronizable.blank?
        raise Errors::SynchronizableNotFound
      end

      element.synchronizable.validate_synchronizable!

      if element.discarded?
        raise Errors::ElementDiscarded
      end

      if element.synchronizable.respond_to?(:discarded?) && element.synchronizable.discarded?
        raise Errors::SynchronizableDiscarded
      end

      if element.folder.discarded?
        raise Errors::FolderDiscarded
      end

      if element.synchronizable.conflicted?
        raise Errors::ElementConflicted
      end

      unless element.pending_local_sync?
        raise Errors::Error, "invalid ne_status: #{element.ne_status}"
      end

      if !element_version.internal?
        raise Errors::Error, "invalid ElementVersion: must be internal"
      end

      if element_version.etag.present?
        raise Errors::Error, "invalid ElementVersion: etag must be blank"
      end

      unless element_version.pending_sync?
        raise Errors::Error, "invalid ElementVersion: must be pending_sync"
      end
    end

    def update_element_version(service_response)
      # TODO!: maybe some lock here
      element_version.update!(
        nev_status: :synced,
        etag: service_response.etag,
        payload: service_response.payload
      )

      element.update_ne_status!
    end
  end
end
