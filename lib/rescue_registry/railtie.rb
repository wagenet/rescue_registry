# frozen_string_literal: true

module RescueRegistry
  class Railtie < Rails::Railtie
    initializer "rescue_registry.add_middleware" do |app|
      # We add this middleware to ensure that the RescueRegistry.context is properly handled.
      # The context is set in the controller action and will be available until the Middleware
      # returns. Any middleware that are before this one will not have access to the context.
      app.middleware.insert_before ::ActionDispatch::ShowExceptions, RescueRegistry::ResetContext
    end
  end
end
