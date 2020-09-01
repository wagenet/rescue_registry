module RescueRegistry
  class ExceptionsApp
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ::ActionDispatch::Request.new(env)
      exception = request.get_header "action_dispatch.exception"

      if RescueRegistry.handles_exception?(exception)
        content_type = request.formats.first || Mime[:text]
        response = RescueRegistry.response_for_public(content_type, exception)
      end

      if response
        status, body, format = response

        if request.path_info != "/#{status}"
          warn "status mismatch; path_info=#{request.path_info}; status=#{status}"
        end

        [status, { "Content-Type" => "#{format}; charset=#{::ActionDispatch::Response.default_charset}",
          "Content-Length" => body.bytesize.to_s }, [body]]
      else
        # If we have no response, it means one of the following:
        # * RescueRegistry doesn't handle this exception
        # * RescueRegistry doesn't have a response to render for this content_type.
        # In either case, we use the default handler instead
        @app.call(env)
      end
    end
  end
end
