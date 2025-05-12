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

    # ----------------------------------------------------

    module Relations
      def included(base)
        base.has_many :nexo_elements, class_name: "Nexo::Element", as: :synchronizable
      end
    end

    def update_from!(element_version)
      transaction do
        # TODO: parse the element_version.payload
        # and set the Synchronizable fields according to the Folder#protocol

        new_sequence = increment_sequence!
        element_version.update_sequence!(new_sequence)
      end
    end

    def increment_sequence!
      # This operation is performed directly in the database without the need
      # to read the current value first. So, it is atomic at a database level,
      # though the in-memory object consitency is subject to race conditions.
      #
      # https://api.rubyonrails.org/v7.2/classes/ActiveRecord/Persistence.html#method-i-increment-21
      increment!(:sequence)
    end

    def mark_as_conflicted!
      update!(conflicted: true)

      # TODO: log "Conflicted Element: #{element.gid}"
    end
  end
end
