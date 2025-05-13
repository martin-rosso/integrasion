module Nexo
  class BaseJob < ActiveJob::Base
    def self.limits_concurrency(*)
      # FIXME: implementar
      puts "ERROR: Implementar limits_concurrency"
    end
  end
end
