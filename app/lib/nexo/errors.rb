module Nexo
  class Errors
    class Error < StandardError; end

    class SynchronizableInvalid < Error; end
    class ConflictingRemoteElementChange < Error; end

    # From here on, classes are subject to review
    # A lot of them are never rescued explicitly
    class ElementConflicted < Error; end
    class ElementAlreadySynced < Error; end
    class MoreThanOneElementInFolderForSynchronizable < Error; end
    class InvalidFolderState < Error; end
    class FolderDiscarded < Error; end
    class SynchronizableDiscarded < Error; end

    # on ControllerHelper
    class InvalidParamsError < Error; end

    # on Synchronizable
    class InterfaceMethodNotImplemented < Error; end

    # on EventReceiver
    class InvalidSynchronizableState < Error; end

    class SynchronizableConflicted < Error; end
    class ElementDiscarded < Error; end
    class SynchronizableNotFound < Error; end
    class SynchronizableSequenceIsNull < Error; end
    class LastSyncedSequenceBiggerThanCurrentOne < Error; end
  end
end
