module Nexo
  module Synchronizable
    extend ActiveSupport::Concern

    def protocol_methods
      # uuid (deprecated)
      #   hay un problema con generar un uuid por synchronizable y es que si se
      #   inserta en un google calendar y luego se elimina, luego ya no se
      #   puede volver a insertar con el mismo uuid, sería mejor que el id se
      #   genere automáticamente por google y guardarlo en Element
      %i[
        sequence
      ]
    end

    module ClassMethods
      def define_protocol(name, methods)
        define_method(:protocols) do
          if defined? super
            # :nocov: TODO, not yet implemented
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

    # :nocov: borderline
    def validate_synchronizable!
      raise "must be implemented in subclass"
    end

    def assign_fields!(fields)
      raise "must be implemented in subclass"
    end
    # :nocov:

    # @raise ActiveRecord::RecordNotUnique
    def update_from!(element_version)
      transaction do
        service = ServiceBuilder.instance.build_protocol_service(element_version.element.folder)
        fields = service.fields_from_version(element_version)

        # and set the Synchronizable fields according to the Folder#nexo_protocol
        assign_fields!(fields)

        # TODO!: maybe some lock here?
        # si esto se ejecuta en paralelo con SynchronizableChangedJob? (para otro
        # element del mismo synchronizable) puede haber race conditions
        increment_sequence!
        reload

        # FIXME: all previous external pending_sync versions must be marked as superseded
        element_version.update!(sequence: sequence, nev_status: :synced)
      end
    end

    def increment_sequence!
      if sequence.nil?
        Rails.logger.warn("Synchronizable sequence is nil on increment_sequence!: #{self.to_gid}")
      end

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
