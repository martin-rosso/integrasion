module Nexo
  class Errors
    class Error < StandardError; end

    class InvalidParamsError < Error; end

    class InterfaceMethodNotImplemented < Error; end

    class InvalidSynchronizableState < Error; end

    class SyncElementJobError < Errors::Error; end
    class SynchronizableConflicted < SyncElementJobError; end
    class ElementConflicted < SyncElementJobError; end
    class ElementDiscarded < SyncElementJobError; end
    class SynchronizableNotFound < SyncElementJobError; end
  end
end
