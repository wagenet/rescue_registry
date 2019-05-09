ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "rspec/rails"
require "rspec/mocks"

module SpecHelpers
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
  config.include SpecHelpers

  config.example_status_persistence_file_path = File.expand_path(".rspec-examples.txt", __dir__)

  config.mock_with :rspec

  config.use_transactional_fixtures = true
end
