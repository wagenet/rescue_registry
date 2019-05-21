module RescueRegistry
  module ActionDispatch
    module ExceptionWrapper
      def status_code_for_exception(class_name)
        RescueRegistry.status_code_for_exception(class_name, passthrough: false) || super
      end
    end
  end
end
