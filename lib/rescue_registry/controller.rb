module RescueRegistry
  module Controller
    def self.included(base)
      base.cattr_accessor :rescue_registry, default: { }
      base.around_action :set_rescue_registry_context
      base.send(:extend, ClassMethods)
    end

    def self.inherited(subklass)
      super
      subklass.rescue_registry = rescue_registry.dup
    end

    def rescue_registry
      self.class.rescue_registry
    end

    private

    def set_rescue_registry_context
      # Set this here so we can still access after we leave the controller
      request.set_header("rescue_registry.context", self)

      # Setting something globally is not very nice, but it allows us to access it without
      # having to change a whole lot of internal Rails APIs. This especially matters when
      # getting the status code via ExceptionWrapper.
      RescueRegistry.with_context(self) { yield }
    end

    module ClassMethods
      def default_exception_handler
        ExceptionHandler
      end

      # TODO: Support a shorthand for handler
      def register_exception(exception_class, handler: default_exception_handler, **options)
        status = options[:status] || handler.try(:status)
        raise ArgumentError, "need to provide a status or a handler that responds_to status" unless status

        rescue_registry[exception_class.name] = [status, handler, options]
      end
    end
  end
end
