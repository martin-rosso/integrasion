module Nexo
  class Errors
    class Error < StandardError; end

    # on ControllerHelper
    class InvalidParamsError < Error; end

    # on Synchronizable
    class InterfaceMethodNotImplemented < Error; end

    # on EventReceiver
    class InvalidSynchronizableState < Error; end

    # on SyncElementJob
    class SyncElementJobError < Errors::Error; end
    class SynchronizableConflicted < SyncElementJobError; end
    class ElementConflicted < SyncElementJobError; end
    class ElementDiscarded < SyncElementJobError; end
    class SynchronizableNotFound < SyncElementJobError; end
    class SynchronizableSequenceIsNull < SyncElementJobError; end
    class LastSyncedSequenceBiggerThanCurrentOne < SyncElementJobError; end
  end
end
