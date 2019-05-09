ActionDispatch::ExceptionWrapper.class_eval do
  class << self
    alias_method :status_code_for_exception_without_rescue_registry, :status_code_for_exception
    def status_code_for_exception(class_name)
      RescueRegistry.status_code_for_exception(class_name) ||
        status_code_for_exception_without_rescue_registry(class_name)
    end
  end
end

# Since this is for debugging only it's less critical to make changes here. The main area that matters is
# returning the correct status code. Since all this code relies upon the ExceptionWrapper which we've monkeypatched,
# it should work correctly without changes. However, we can provide more details in some areas so we hook in for that.
ActionDispatch::DebugExceptions.class_eval do
  private

  if private_method_defined?(:invoice_interceptors)
    alias_method :invoke_interceptors_without_rescue_registry, :invoke_interceptors
    def invoke_interceptors(request, exception)
      # Since ExceptionWrapper is used here we need to wrap in the context
      RescueRegistry.with_context(request.get_header("rescue_registry.context")) do
        invoke_interceptors_without_rescue_registry(request, exception)
      end
    end
  end

  alias_method :render_exception_without_rescue_registry, :render_exception
  def render_exception(request, exception)
    # Since ExceptionWrapper is used here we need to wrap in the context
    RescueRegistry.with_context(request.get_header("rescue_registry.context")) do
      render_exception_without_rescue_registry(request, exception)
    end
  end

  # `#log_error`
  # TODO: We may be able to add more information, though the details remain to be determined

  # `#render_for_browser_request`
  # TODO: We may be able to add more information, though the details remain to be determined

  # This would work without changes, but the formatting would be incorrect. Since it's for debugging only,
  # we could choose to ignore it, but the detailed information would definitely be useful.
  alias_method :render_for_api_request_without_rescue_registry, :render_for_api_request
  def render_for_api_request(content_type, wrapper)
    if RescueRegistry.handles_exception?(wrapper.exception)
      # Ideally `render_for_api_request` would be split up so we could avoid some duplication in `response_for_api_request`
      render(*RescueRegistry.response_for_debugging(content_type, wrapper))
    else
      render_for_api_request_without_rescue_registry(content_type, wrapper)
    end
  end
end

ActionDispatch::ShowExceptions.class_eval do
  # @private
  alias_method :initialize_without_graphiti, :initialize

  # @private
  def initialize(*args)
    initialize_without_graphiti(*args)
    @exceptions_app = RescueRegistry::ExceptionsApp.new(@exceptions_app)
  end

  private

  alias_method :render_exception_without_rescue_registry, :render_exception
  def render_exception(request, exception)
    # Since ExceptionWrapper is used here we need to wrap in the context
    RescueRegistry.with_context(request.get_header("rescue_registry.context")) do
      render_exception_without_rescue_registry(request, exception)
    end
  end
end
