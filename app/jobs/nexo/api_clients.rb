module Nexo
  module ApiClients
    extend ActiveSupport::Concern

    included do
      include GoodJob::ActiveJobExtensions::Concurrency

      queue_as :api_clients

      # TODO: make this configurable, so other job backends are allowed
      good_job_control_concurrency_with(
        perform_limit: 1,

        perform_throttle: (Nexo.api_jobs_throttle || [ 100, 5.minute ]),

        key: -> { "#{queue_name}" }
      )

      retry_on(
        GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
        attempts: Float::INFINITY,
        wait: ->(executions) { ((executions**3) + (Kernel.rand * (executions**3) * 0.5)) + 2 }
      )
    end
  end
end
