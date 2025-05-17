module Nexo
  class Errors
    class Error < StandardError; end

    class ElementConflicted < Error; end
    class ExternalUnsyncedChange < Error; end
    class ElementAlreadySynced < Error; end
    class MoreThanOneElementInFolderForSynchronizable < Error; end

    # on ControllerHelper
    class InvalidParamsError < Error; end

    # on Synchronizable
    class InterfaceMethodNotImplemented < Error; end

    # on EventReceiver
    class InvalidSynchronizableState < Error; end

    # on SyncElementJob
    class SyncElementJobError < Errors::Error; end
    class SynchronizableConflicted < Error; end
    class ElementDiscarded < Error; end
    class SynchronizableNotFound < Error; end
    class SynchronizableSequenceIsNull < Error; end
    class LastSyncedSequenceBiggerThanCurrentOne < Error; end
  end
end
