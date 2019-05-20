module RescueRegistry
  module ActionDispatch
    module ShowExceptions
      def initialize(*args)
        super
        @exceptions_app = RescueRegistry::ExceptionsApp.new(@exceptions_app)
      end

      def call(*args)
        warn "Didn't expect RescueRegistry context to be set in middleware" if RescueRegistry.context
        super
      ensure
        RescueRegistry.context = nil
      end
    end
  end
end
