module Nexo
  class BaseJob < ActiveJob::Base
    # Like ActiveJob does with Rails.logger, we do with Nexo.logger
    # push job's name and id tags
    around_perform do |job, block|
      tags = job.class.name, job.job_id
      Nexo.plain_logger.tagged(*tags, &block)
    end
  end
end
