require "rspec/core"
require "rspec/mocks"

RSpec.configure do |config|
  config.example_status_persistence_file_path = File.expand_path(".rspec-examples.txt", __dir__)

  config.mock_with :rspec
end
