ENV["RAILS_ENV"] ||= "test"

if Rails::VERSION::MAJOR < 7
  require_relative "rails5/dummy/config/environment"
else
  require_relative "rails7/dummy/config/environment"
end

require_relative "spec_helper"
require "rspec/rails"

# If we ran the Rack specs first, these won't have been required
require 'rescue_registry/action_dispatch'
require 'rescue_registry/railtie'

RSpec.configure do |config|
  config.include RescueRegistry::RailsTestHelpers

  config.use_transactional_fixtures = false
end
