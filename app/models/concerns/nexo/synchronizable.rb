module Nexo
  module Synchronizable
    extend ActiveSupport::Concern

    def protocol_methods
      %i[
        uuid
        sequence
        conflicted?
        conflicted=
      ]
    end

    module ClassMethods
      def define_protocol(name, methods)
        define_method(:protocols) do
          if defined? super
            super << name
          else
            [ name ]
          end
        end

        define_method(:protocol_methods) do
          if defined? super
            [ super(), methods ].flatten
          else
            methods
          end
        end
      end
    end

    def method_missing(method_name, *, &)
      if method_name.in?(protocol_methods)
        raise Errors::InterfaceMethodNotImplemented, method_name
      end

      super
    end
  end
end
