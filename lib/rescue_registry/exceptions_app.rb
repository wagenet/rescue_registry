module RescueRegistry
  class ExceptionsApp
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      exception = request.get_header "action_dispatch.exception"

      if RescueRegistry.handles_exception?(exception)
        begin
          content_type = request.formats.first
        rescue Mime::Type::InvalidMimeType
          content_type = Mime[:text]
        end

        if (response = RescueRegistry.response_for_public(content_type, exception))
          status, body, format = response

          if request.path_info != "/#{status}"
            warn "status mismatch; path_info=#{request.path_info}; status=#{status}"
          end

          [status, { "Content-Type" => "#{format}; charset=#{ActionDispatch::Response.default_charset}",
            "Content-Length" => body.bytesize.to_s }, [body]]
        else
          # If we have no response, it means we couldn't render for the content_type, use the default handler instead
          @app.call(env)
        end
      else
        @app.call(env)
      end
    end
  end
end
