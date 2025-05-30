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

    def register_folder_rule_finder(&block)
      @finders << block
    end

    attr_reader :finders

    def applies?(folder, synchronizable)
      policies = policies_for(folder)
      applied_policies = policies.select { |policy| policy.applies?(synchronizable) }
      # :nocov: TODO
      if applied_policies.any?
        aplicable_policy = applied_policies.sort_by { |policy| policy.priority }.last
        logger.debug { "Aplicable policy: #{aplicable_policy.inspect}" }

        aplicable_policy.sync_policy.to_s == "include"
      else
        logger.debug { "No applicable policies" }
        false
      end
      # :nocov:
    end

    def policies_for(folder)
      logger.debug { "Found #{@finders.length} finders" }

      aux = @finders.map do |finder|
        finder.call(folder)
      end

      aux.flatten.compact.tap do |ret|
        logger.debug { "Found #{ret.length} policies" }
      end
    end

    private

    def logger
      logger = Nexo.logger.tagged("PolicyService")
    end
  end
end
