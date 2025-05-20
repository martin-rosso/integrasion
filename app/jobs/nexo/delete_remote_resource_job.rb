module Nexo
  class DeleteRemoteResourceJob < BaseJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      perform_throttle: [ 100, 5.minute ],
      key: -> { "#{queue_name}" }
    )

    retry_on(
      GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
      attempts: Float::INFINITY,
      wait: ->(executions) { ((executions**3) + (Kernel.rand * (executions**3) * 0.5)) + 2 }
      # wait: -> (executions) { 30.seconds + (200 * Kernel.rand) }
    )

    queue_as :api_clients

    def perform(element)
      ServiceBuilder.instance.build_protocol_service(element.folder).remove(element)
    end
  end
end
