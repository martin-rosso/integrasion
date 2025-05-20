module Nexo
  class PolicyService
    def initialize
      @finders = []
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
      policy = policy_for(folder)
      matching_policy = policy.select { |policy| policy.match?(synchronizable) }
      if matching_policy.any?
        # TODO: find better name
        best_policy = matching_policy.sort_by { |policy| policy.priority }.last
        best_policy.sync_policy == :include
      else
        false
      end
    end

    def policy_for(folder)
      aux = @finders.map do |finder|
        finder.call(folder)
      end

      aux.flatten.compact
    end
  end
end
