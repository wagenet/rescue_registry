ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require_relative "spec_helper"
require "rspec/rails"

# If we ran the Rack specs first, these won't have been required
require 'rescue_registry/action_dispatch'
require 'rescue_registry/railtie'

RSpec.configure do |config|
  config.include RescueRegistry::RailsTestHelpers

  config.use_transactional_fixtures = true
end
