module RescueRegistry
  class Registry
    attr_accessor :owner

    def initialize(owner)
      @owner = owner
      @handlers = { }
    end

    def initialize_dup(_other)
      @handlers = @handlers.dup
    end

    def passthrough_allowed?
      defined?(ActionDispatch::ExceptionWrapper)
    end

    def passthrough_status(exception)
      ::ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
    end

    # TODO: Support a shorthand for handler
    def register_exception(exception_class, handler: nil, **options)
      raise ArgumentError, "#{exception_class} is not an Exception" unless exception_class <= Exception

      if owner.respond_to?(:default_exception_handler)
        handler ||= owner.default_exception_handler
      end
      raise ArgumentError, "handler must be provided" unless handler

      status = options[:status] ||= handler.default_status
      raise ArgumentError, "status must be provided" unless status
      unless status.is_a?(Integer) || (passthrough_allowed? && status == :passthrough)
        raise ArgumentError, "invalid status: #{status}"
      end

      # TODO: Validate options here

      # We assign the status here as a default when looking up by class (and not instance)
      @handlers[exception_class] = [handler, options]
    end

    def handler_for_exception(exception)
      handler_info = handler_info_for_exception(exception)
      raise HandlerNotFound, "no handler found for #{exception.class}" unless handler_info

      handler_class, handler_options = handler_info

      if handler_options[:status] == :passthrough
        handler_options[:status] = passthrough_status(exception)
      end

      handler_class.new(exception, **handler_options)
    end

    def handles_exception?(exception)
      !handler_info_for_exception(exception).nil?
    end

    def status_code_for_exception(exception, passthrough: true)
      _, options = handler_info_for_exception(exception)
      return unless options

      if options[:status] == :passthrough
        passthrough ? passthrough_status(exception) : nil
      else
        options[:status]
      end
    end

    def build_response(content_type, exception, **options)
      handler = handler_for_exception(exception)
      handler.formatted_response(content_type, **options)
    end

    def response_for_debugging(content_type, exception, traces: nil, fallback: :none)
      build_response(content_type, exception, show_details: true, traces: traces, fallback: fallback)
    end

    def response_for_public(content_type, exception, fallback: :none)
      build_response(content_type, exception, fallback: fallback)
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
