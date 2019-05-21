module RescueRegistry
  module ActionDispatch
    autoload :DebugExceptions,  "rescue_registry/action_dispatch/debug_exceptions"
    autoload :ExceptionWrapper, "rescue_registry/action_dispatch/exception_wrapper"
    autoload :ShowExceptions,   "rescue_registry/action_dispatch/show_exceptions"
  end
end
