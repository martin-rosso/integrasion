module Nexo
  module FolderPolicy
    extend ActiveSupport::Concern
    # include ActiveModel::Model
    include ActiveModel::Validations

    # validates_inclusion_of :sync_policy, in: %w( include exclude )
    # FIXME: check if this is being used
    included do
      validates :sync_policy, inclusion: { in: %w[ bla ] }
      validates :priority, numericality: true
    end

    def match?(synchronizable)
      # :nocov: borderline
      raise "must be implemented in subclass"
      # :nocov:
    end

    attr_reader :priority, :sync_policy
  end
end
