module RescueRegistry
  # Helpers to improve the ease of testing error handling in Rails tests.
  # These are not actually specific to RescueRegistry, but will certainly be useful for it.
  module RailsTestHelpers
    def handle_request_exceptions(handle = true, &block)
      set_action_dispatch_property(:show_exceptions, handle, &block)
    end

    def handle_request_exceptions?
      Rails.application.config.action_dispatch.show_exceptions
    end

    def show_detailed_exceptions(show = true, &block)
      set_action_dispatch_property(:show_detailed_exceptions, show, &block)
    end

    def show_detailed_exceptions?
      Rails.application.config.action_dispatch.show_detailed_exceptions
    end

    private

    def set_action_dispatch_property(key, value)
      if block_given?
        original_value = Rails.application.config.action_dispatch.send(key)
      end

      Rails.application.config.action_dispatch.send("#{key}=", value)
      # Also set this since it may have been cached
      Rails.application.env_config["action_dispatch.#{key}"] = value

      if block_given?
        begin
          yield
        ensure
          Rails.application.env_config["action_dispatch.#{key}"] = original_value
          Rails.application.config.action_dispatch.send("#{key}=", original_value)
        end
      end
    end
  end
end
