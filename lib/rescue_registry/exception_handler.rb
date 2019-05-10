module RescueRegistry
  class ExceptionHandler
    def self.default_status
      500
    end

    # Use a glob for options so that unknown values won't throw errors. Also, this list could get long...
    def initialize(exception, **options)
      @exception = exception

      status = options[:status]
      if status == :passthrough
        status = ActionDispatch::ExceptionWrapper.status_code_for_exception_without_rescue_registry(exception.class.name)
      end
      @status = status

      @title = options[:title]

      @detail = options[:detail]
      if options[:message] && @detail.nil?
        # Deprecated, from GraphitiErrors
        @detail = (options[:message] == true) ? :exception : options[:message]
      end

      @meta = options[:meta]

      # TODO: Warn about unrecognized options
    end

    attr_reader :exception, :status
    alias_method :status_code, :status

    def error_code
      error_code_from_status
    end

    def title
      @title || title_from_status
    end

    def detail
      detail =
        case @detail
        when :exception
          exception.message
        when Proc
          @detail.call(exception)
        else
          @detail.try(:to_s)
        end

      detail.presence || default_detail_for_status
    end

    def meta
      if @meta.is_a?(Proc)
        @meta.call(exception)
      else
        { }
      end
    end

    def build_payload(show_details: false, traces: nil)
      payload_meta = meta

      if show_details
        payload_meta = payload_meta.merge(
          __details__: {
            exception: exception.inspect,
            traces: traces || [exception.backtrace]
          }
        )
      end

      {
        errors: [
          code: error_code,
          status: status_code.to_s,
          title: title,
          detail: detail,
          meta: payload_meta
        ]
      }
    end

    def formatted_response(content_type, fallback: :json, **options)
      body = build_payload(**options)

      # TODO: Maybe make a helper to register these types?
      to_format = content_type == :jsonapi ? "to_json" : "to_#{content_type.to_sym}"

      if content_type && body.respond_to?(to_format)
        formatted_body = body.public_send(to_format)
        format = content_type
      else
        if fallback == :json
          formatted_body = body.to_json
          format = Mime[:json]
        elsif fallback == :none
          return nil
        else
          raise ArgumentError, "unknown fallback=#{fallback}"
        end
      end

      [status_code, formatted_body, format]
    end

    private

    def error_code_from_status
      code_to_symbol = Rack::Utils::SYMBOL_TO_STATUS_CODE.invert
      code_to_symbol.fetch(status_code, code_to_symbol[500])
    end

    def title_from_status
      Rack::Utils::HTTP_STATUS_CODES.fetch(
        status_code,
        Rack::Utils::HTTP_STATUS_CODES[500]
      )
    end

    def default_detail_for_status
      if status_code >= 500
        "We've notified our engineers and hope to address this issue shortly."
      end
    end
  end

  # Builds a payload in the style of the Rails default handling for compatibility
  class RailsExceptionHandler < ExceptionHandler
    def build_payload(show_details: false, traces: nil)
      body = {
        status: status_code,
        error:  title
      }

      if show_details
        body[:exception] = exception.inspect
        if traces
          body[:traces] = traces
        end
      end

      body
    end
  end
end
