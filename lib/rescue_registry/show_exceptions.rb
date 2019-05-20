# frozen_string_literal: true

# This is for use in non-Rails Rack apps. Rails apps will handle exceptions with
# ActionDispatch::DebugExceptions and ActionDispatch::ShowExceptions
module RescueRegistry
  class ShowExceptions
    # Unfortunately, Rail's nice mime types are in ActionDispatch which we'd rather not require
    CONTENT_TYPES = {
      jsonapi: "application/vnd.api+json",
      json:    "application/json",
      xml:     ["application/xml", "text/xml"],
      plain:   "text/plain"
    }

    # Match Rail's Mime::Type API on a basic level
    MimeType = Struct.new(:to_sym, :to_s)

    def initialize(app, debug: false, content_types: CONTENT_TYPES)
      @app = app
      @content_types = content_types
      @debug = debug
    end

    def call(env)
      @app.call(env)
    rescue Exception => exception
      handle_exception(env, exception)
    end

    private

    def handle_exception(env, exception)
      if RescueRegistry.handles_exception?(exception)
        accept = Rack::Utils.best_q_match(env["HTTP_ACCEPT"], @content_types.values.flatten)
        accept ||= "text/plain"

        symbol = CONTENT_TYPES.find { |(k,v)| Array(v).include?(accept) }.first
        content_type = MimeType.new(symbol, accept)

        # We need a fallback to ensure that we actually do render something. Outside of Rails, there's no situation where
        # we would want to pass through on a handled exception.
        fallback = MimeType.new(:json, CONTENT_TYPES[:json])
        if @debug
          response = RescueRegistry.response_for_debugging(content_type, exception, traces: { "Full Trace" => exception.backtrace }, fallback: fallback)
        else
          response = RescueRegistry.response_for_public(content_type, exception, fallback: fallback)
        end
      end

      if response
        status, body, format = response
        [status, { "Content-Type" => "#{format}", "Content-Length" => body.bytesize.to_s }, [body]]
      else
        # Let next middleware handle
        raise exception
      end
    end
  end
end
