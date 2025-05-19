module Nexo
  class RulesService
    def initialize
      @finders = []
    end

    @instance = new

    private_class_method :new

    def self.instance
      @instance
    end

    # @todo FIXME: find a better name
    def register_finder(&block)
      @finders << block
    end

    attr_reader :finders

    def match?(folder, synchronizable)
      rules = rules_for(folder)
      matching_rules = rules.select { |rule| rule.match?(synchronizable) }
      if matching_rules.any?
        best_rule = matching_rules.sort_by { |rule| rule.priority }.last
        best_rule.sync_policy == :include
      else
        false
      end
    end

    def rules_for(folder)
      aux = @finders.map do |finder|
        finder.call(folder)
      end

      aux.flatten.compact
    end
  end
end
