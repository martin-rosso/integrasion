module Nexo
  class UpdateRemoteResourceJob < BaseJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      # Maximum number of jobs with the concurrency key to be
      # concurrently performed (excludes enqueued jobs)
      # Can be an Integer or Lambda/Proc that is invoked in the context of the job
      perform_limit: 1,

      # Maximum number of jobs with the concurrency key to be performed within
      # the time period, looking backwards from the current time. Must be an array
      # with two elements: the number of jobs and the time period.
      perform_throttle: [ 100, 5.minute ],

      # Note: Under heavy load, the total number of jobs may exceed the
      # sum of `enqueue_limit` and `perform_limit` because of race conditions
      # caused by imperfectly disjunctive states. If you need to constrain
      # the total number of jobs, use `total_limit` instead. See #378.

      # A unique key to be globally locked against.
      # Can be String or Lambda/Proc that is invoked in the context of the job.
      #
      # If a key is not provided GoodJob will use the job class name.
      #
      # To disable concurrency control, for example in a subclass, set the
      # key explicitly to nil (e.g. `key: nil` or `key: -> { nil }`)
      #
      # If you provide a custom concurrency key (for example, if concurrency is supposed
      # to be controlled by the first job argument) make sure that it is sufficiently unique across
      # jobs and queues by adding the job class or queue to the key yourself, if needed.
      #
      # Note: When using a model instance as part of your custom concurrency key, make sure
      # to explicitly use its `id` or `to_global_id` because otherwise it will not stringify as expected.
      #
      # Note: Arguments passed to #perform_later can be accessed through Active Job's `arguments` method
      # which is an array containing positional arguments and, optionally, a kwarg hash.
      # key: -> { "#{self.class.name}-#{queue_name}-#{arguments.first}-#{arguments.last[:version]}" } #  MyJob.perform_later("Alice", version: 'v2') => "MyJob-default-Alice-v2"
      key: -> { "#{queue_name}" }
    )

    queue_as :api_clients

    retry_on(
      GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
      attempts: Float::INFINITY,
      wait: ->(executions) { ((executions**3) + (Kernel.rand * (executions**3) * 0.5)) + 2 }
      # wait: -> (executions) { 30.seconds + (200 * Kernel.rand) }
    )

    attr_reader :element

    def perform(element)
      @element = element

      validate_element_state!

      remote_service = ServiceBuilder.instance.build_protocol_service(element.folder)

      response =
        if element.element_versions.any?
          remote_service.update(element)
        else
          remote_service.insert(element.folder, element.synchronizable).tap do |response|
            element.update(uuid: response.id)
          end
        end

      save_element_version(response)
    end

    private

    def validate_element_state!
      if element.synchronizable.conflicted?
        raise Errors::ElementConflicted
      end

      if element.external_unsynced_change?
        raise Errors::ExternalUnsyncedChange
      end

      current_sequence = element.synchronizable.sequence
      last_synced_sequence = element.last_synced_sequence

      unless current_sequence > last_synced_sequence
        raise Errors::ElementAlreadySynced
      end
    end

    # @todo sequence should be fetched before to avoid being outdated
    def save_element_version(service_response)
      ElementVersion.create!(
        element:,
        origin: :internal,
        etag: service_response.etag,
        payload: service_response.payload,
        sequence: element.synchronizable.sequence,
      )
    end
  end
end
