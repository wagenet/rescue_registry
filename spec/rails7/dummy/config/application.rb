require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require "rescue_registry"

if Mime[:jsonapi].nil?
  Mime::Type.register("application/vnd.api+json", :jsonapi)
end

class GlobalError < StandardError; end
class OtherGlobalError < StandardError; end

module RescueRegistryTest
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.debug_exception_response_format = :api

    initializer "register_global_exception" do
      ActiveSupport.on_load(:action_controller) do
        register_exception GlobalError, status: 400
      end
    end
  end
end
