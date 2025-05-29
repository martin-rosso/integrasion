module Nexo
  module FolderPolicy
    extend ActiveSupport::Concern
    # TODO: raise if subclass not implements required methods

    def applies?(synchronizable)
      # :nocov: borderline
      raise "must be implemented in subclass"
      # :nocov:
    end

    attr_reader :priority, :sync_policy
  end
end
