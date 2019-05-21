module RescueRegistry
  module ActionDispatch
    # Since this is for debugging only it's less critical to make changes here. The main area that matters is
    # returning the correct status code. Since all this code relies upon the ExceptionWrapper which we've monkeypatched,
    # it should work correctly without changes. However, we can provide more details in some areas so we hook in for that.
    module DebugExceptions
      private

      # `#log_error`
      # TODO: We may be able to add more information, though the details remain to be determined

      # `#render_for_browser_request`
      # TODO: We may be able to add more information, though the details remain to be determined

      # This would work without changes, but the formatting would be incorrect. Since it's for debugging only,
      # we could choose to ignore it, but the detailed information would definitely be useful.
      def render_for_api_request(content_type, wrapper)
        response = nil

        if RescueRegistry.handles_exception?(wrapper.exception)
          # Ideally `render_for_api_request` would be split up so we could avoid some duplication in RescueRegistry
          begin
            response = RescueRegistry.response_for_debugging(content_type, wrapper.exception, traces: wrapper.traces)
          rescue Exception => e
            # Replace the original exception (still available via `cause`) and let it get handled with default handlers
            wrapper = ActionDispatch::ExceptionWrapper.new(wrapper.backtrace_cleaner, e)
          end
        end

        if response
          render(*response)
        else
          # One of the following is true:
          # - No handler for the exception
          # - No response for content_type
          # - An exception while generating the response
          # In any case, we go with the default here.
          super(content_type, wrapper)
        end
      end
    end
  end
end
