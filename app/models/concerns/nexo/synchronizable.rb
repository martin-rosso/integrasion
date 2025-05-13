module Nexo
  module Synchronizable
    extend ActiveSupport::Concern

    def protocol_methods
      %i[
        uuid
        sequence
      ]
    end

    module ClassMethods
      def define_protocol(name, methods)
        define_method(:protocols) do
          if defined? super
            # :nocov: FIXME, not yet implemented
            super << name
            # :nocov:
          else
            [ name ]
          end
        end

        define_method(:protocol_methods) do
          if defined? super
            [ super(), methods ].flatten
          else
            # :nocov: borderline
            raise "protocol_methods should be defined"
            # :nocov:
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

    # ----------------------------------------------------

    module Associations
      extend ActiveSupport::Concern
      included do
        has_many :nexo_elements, class_name: "Nexo::Element", as: :synchronizable
      end
    end

    def conflicted?
      nexo_elements.conflicted.any?
    end

    # :nocov: FIXME, not yet implemented
    def update_from!(element_version)
      transaction do
        # TODO: parse the element_version.payload
        # and set the Synchronizable fields according to the Folder#protocol

        new_sequence = increment_sequence!
        element_version.update_sequence!(new_sequence)
      end
    end
    # :nocov:

    def increment_sequence!
      # This operation is performed directly in the database without the need
      # to read the current value first. So, it is atomic at a database level,
      # though the in-memory object consitency is subject to race conditions.
      #
      # increment(:sequence), without the bang, is not atomic
      #
      # https://api.rubyonrails.org/v7.2/classes/ActiveRecord/Persistence.html#method-i-increment-21
      increment!(:sequence)
    end
  end
end
