ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require_relative "spec_helper"
require "rspec/rails"

# If we ran the Rack specs first, these won't have been required
require 'rescue_registry/action_dispatch'
require 'rescue_registry/railtie'

module RailsSpecHelpers
  def handle_request_exceptions(handle = true)
    original_value = Rails.application.config.action_dispatch.handle_exceptions

    Rails.application.config.action_dispatch.handle_exceptions = handle
    # Also set this since it may have been cached
    Rails.application.env_config["action_dispatch.show_exceptions"] = handle

    yield

    Rails.application.env_config["action_dispatch.show_exceptions"] = original_value
    Rails.application.config.action_dispatch.handle_exceptions = original_value
  end

  def show_detailed_exceptions(show = true)
    original_value = Rails.application.config.action_dispatch.show_detailed_exceptions

    Rails.application.config.action_dispatch.show_detailed_exceptions = show
    # Also set this since it may have been cached
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = show

    yield

    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = original_value
    Rails.application.config.action_dispatch.show_detailed_exceptions = original_value
  end
end

RSpec.configure do |config|
  config.include RailsSpecHelpers

  config.use_transactional_fixtures = true
end
