module RescueRegistry
  module Context
    extend ActiveSupport::Concern

    included do
      if respond_to?(:class_attribute)
        # Prevents subclasses from sharing, but only available to classes
        class_attribute :rescue_registry
      else
        # Allows this module to be included in a module
        mattr_accessor :rescue_registry
      end

      self.rescue_registry = Registry.new(self)

      class << self
        delegate :register_exception, to: :rescue_registry
      end
    end

    def rescue_registry
      self.class.rescue_registry
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
