module Nexo
  class BaseJob < ActiveJob::Base
    def self.limits_concurrency(*)
      # FIXME: implementar
      # Rails.logger.error "ERROR: Implementar limits_concurrency"
    end
  end
end
