require_relative "spec_helper"
require "rack/test"
require "rescue_registry"

RSpec.describe "Rack App Usage" do
  include Rack::Test::Methods

  class CustomError < StandardError; end

  let :app do
    Rack::Builder.new do
      use Rack::CommonLogger
      # Catch stuff not handled by RescueRegistry
      use Rack::ShowExceptions
      # Handle registered exceptions
      use RescueRegistry::ShowExceptions

      map "/" do
        run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
      end

      map "/error" do
        run lambda { |env| raise "Error" }
      end

      map "/registered-error" do
        run lambda { |env| raise CustomError }
      end
    end
  end

  let :context do
    Module.new do
      include RescueRegistry::Context

      register_exception CustomError, status: 403
    end
  end

  around do |example|
    RescueRegistry.with_context(context) { example.run }
  end

  it "doesn't mess up a normal request" do
    get "/"
    expect(last_response).to be_ok
  end

  it "ignores unregistered errors" do
    get "/error"
    expect(last_response).to_not be_ok
    expect(last_response.body).to include("RuntimeError: Error")
    expect(last_response.content_type).to eq("text/plain")
  end

  it "handles registered errors" do
    get "/registered-error"
    expect(last_response).to_not be_ok
    expect(last_response.status).to eq(403)
    expect(JSON.parse(last_response.body)).to eq({
      "errors" => [
        {
          "code" => "forbidden",
          "status" => "403",
          "title" => "Forbidden"
        }
      ]
    })
  end
end
