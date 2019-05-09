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
  alias_method :initialize_without_rescue_registry, :initialize

  # @private
  def initialize(*args)
    initialize_without_rescue_registry(*args)
    @exceptions_app = RescueRegistry::ExceptionsApp.new(@exceptions_app)
  end

  alias_method :call_without_rescue_registry, :call
  def call(*args)
    warn "Didn't expect RescueRegistry context to be set in middleware" if RescueRegistry.context
    call_without_rescue_registry(*args)
  ensure
    RescueRegistry.context = nil
  end
end
