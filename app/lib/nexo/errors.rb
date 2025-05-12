module Nexo
  class Errors
    class Error < StandardError
    end

    class InvalidParamsError < Error
    end

    class InterfaceMethodNotImplemented < Error
    end
  end
end
