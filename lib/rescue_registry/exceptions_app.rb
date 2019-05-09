module RescueRegistry
  class ExceptionsApp
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      exception = request.get_header "action_dispatch.exception"

      if RescueRegistry.handles_exception?(exception)
        status, body, format = RescueRegistry.response_for_public(content_type, exception)
        [status, { "Content-Type" => "#{format}; charset=#{ActionDispatch::Response.default_charset}",
          "Content-Length" => body.bytesize.to_s }, [body]]
      else
        @app.call(env)
      end
    end
  end
end
