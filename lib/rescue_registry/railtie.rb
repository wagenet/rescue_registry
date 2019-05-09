# frozen_string_literal: true

module RescueRegistry
  class Railtie < Rails::Railtie
    initializer "rescue_registry" do
      ActiveSupport.on_load(:action_controller) do
        include RescueRegistry::Controller
      end
    end
  end
end
