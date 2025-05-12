module Nexo
  class Errors
    class Error < StandardError
    end

    class InvalidParamsError < Error
    end

    class InterfaceMethodNotImplemented < Error
    end

    class InvalidSynchronizableState < Error
    end

    class SynchronizableConflicted < Error
    end
  end
end
