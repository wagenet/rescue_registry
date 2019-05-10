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

      status = options[:status] ||= handler.default_status
      raise ArgumentError, "status must be provided" unless status
      raise ArgumentError, "invalid status: #{status}" unless status.is_a?(Integer) || status == :passthrough

      # TODO: Validate options here

      # We assign the status here as a default when looking up by class (and not instance)
      @handlers[exception_class] = [handler, options]
    end

    def handler_for_exception(exception)
      handler_info = handler_info_for_exception(exception)
      raise HandlerNotFound, "no handler found for #{exception.class}" unless handler_info

      handler_class, handler_options = handler_info
      handler_class.new(exception, **handler_options)
    end

    def handles_exception?(exception)
      handler_info_for_exception(exception).present?
    end

    def status_code_for_exception(exception)
      _, options = handler_info_for_exception(exception)
      return unless options

      # Return no code for passthrough.
      # Alternatively we could handle this explicitly in the ExceptionWrapper monkeypatch.
      options[:status] == :passthrough ? nil : options[:status]
    end

    def build_response(content_type, exception, **options)
      handler = handler_for_exception(exception)
      handler.formatted_response(content_type, **options)
    end

    def response_for_debugging(content_type, exception, traces: nil)
      build_response(content_type, exception, show_details: true, traces: traces)
    end

    def response_for_public(content_type, exception)
      build_response(content_type, exception, fallback: :none)
    end

    private

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
  end
end
