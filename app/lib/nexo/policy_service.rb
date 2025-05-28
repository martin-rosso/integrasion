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

    def match?(folder, synchronizable)
      policies = policies_for(folder)
      matching_policies = policies.select { |policy| policy.match?(synchronizable) }
      if matching_policies.any?
        aplicable_policy = matching_policies.sort_by { |policy| policy.priority }.last
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
