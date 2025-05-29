module Nexo
  class PolicyService
    def clear_finders!
      @finders = []
    end

    def initialize
      clear_finders!
    end

    @instance = new

    private_class_method :new

    def self.instance
      @instance
    end

    def register_folder_policy_finder(&block)
      @finders << block
    end

    attr_reader :finders

    def applies?(folder, synchronizable)
      logger = Nexo.logger.tagged("PolicyService")
      policies = policies_for(folder)
      logger.debug { "Found #{policies.length} policies" }
      applied_policies = policies.select { |policy| policy.applies?(synchronizable) }
      if applied_policies.any?
        aplicable_policy = applied_policies.sort_by { |policy| policy.priority }.last
        aplicable_policy.sync_policy == :include
      else
        false
      end
    end

    def policies_for(folder)
      aux = @finders.map do |finder|
        finder.call(folder)
      end

      aux.flatten.compact
    end
  end
end
