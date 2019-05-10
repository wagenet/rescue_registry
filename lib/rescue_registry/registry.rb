module RescueRegistry
  class Registry
    attr_accessor :owner

    def initialize(owner)
      @owner = self
      @handlers = { }
    end

    def initialize_dup(_other)
      @handlers = @handlers.dup
    end

    # TODO: Support a shorthand for handler
    def register_exception(exception_class, handler: nil, **options)
      raise ArgumentError, "#{exception_class} is not an Exception" unless exception_class <= Exception

      handler ||= owner.try(:default_exception_handler)
      raise ArgumentError, "handler must be provided" unless handler

      status = options[:status] || handler.try(:status)
      raise ArgumentError, "need to provide a status or a handler that responds_to status" unless status

      @handlers[exception_class] = [status, handler, options]
    end

    def handler_info_for_exception(exception)
      exception_class =
        case exception
        when String
          exception.safe_constantize
        when Class
          exception
        else
          exception.class
        end

      return unless exception_class

      raise ArgumentError, "#{exception_class} is not an Exception" unless exception_class <= Exception

      # Reverse so most recently defined takes precedence
      registry = @handlers.to_a.reverse

      # Look for an exact class, then for the superclass and so on.
      # There might be a more efficient way to do this, but this is pretty readable
      match_class = exception_class
      loop do
        if (found = registry.find { |(klass, _)| klass == match_class })
          return found.last
        elsif match_class == Exception
          # We've exhausted our options
          return nil
        end

        match_class = match_class.superclass
      end
    end

    def handler_for_exception(exception)
      handler_info = handler_info_for_exception(exception)
      raise HandlerNotFound, "no handler found for #{exception.class}" unless handler_info

      status, handler_class, handler_options = handler_info
      handler = handler_class.new(exception, **handler_options)

      [status, handler]
    end

    def handles_exception?(exception)
      handler_info_for_exception(exception).present?
    end

    def status_code_for_exception(exception)
      handler_info_for_exception(exception)&.first
    end

    def build_response(content_type, exception, **options)
      status, handler = handler_for_exception(exception)
      formatted_body, format = handler.formatted_payload(content_type, **options)
      [status, formatted_body, format]
    end

    def response_for_debugging(content_type, exception, traces: nil)
      build_response(content_type, exception, show_details: true, traces: traces)
    end

    def response_for_public(content_type, exception)
      build_response(content_type, exception, fallback: :none)
    end
  end
end
