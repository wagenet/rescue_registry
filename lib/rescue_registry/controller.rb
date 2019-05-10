module RescueRegistry
  module Controller
    extend ActiveSupport::Concern

    included do
      cattr_accessor :rescue_registry
      self.rescue_registry = Registry.new(self)

      class << self
        delegate :register_exception, to: :rescue_registry
      end
    end

    def rescue_registry
      self.class.rescue_registry
    end

    def process_action(*args)
      warn "Didn't expect RescueRegistry context to be set in controller" if RescueRegistry.context

      # Setting something globally is not very nice, but it allows us to access it without
      # having to change a whole lot of internal Rails APIs. This especially matters when
      # getting the status code via ExceptionWrapper.
      # We don't unset here so that it is available to middleware
      # Unsetting happens in ActionDispatch::ShowExceptions. This _should_ be ok since we shouldn't
      # be processing multiple requests in the same thread.
      RescueRegistry.context = self

      super
    end

    class_methods do
      def inherited(subklass)
        super
        subklass.rescue_registry = rescue_registry.dup
        subklass.rescue_registry.owner = subklass
      end

      def default_exception_handler
        ExceptionHandler
      end
    end
  end
end
