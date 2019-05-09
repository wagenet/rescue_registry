require_relative "rails_helper"

RSpec.describe "basic behavior", type: :request do
  it "set status code" do
    handle_request_exceptions do
      get "/rescue"
    end
    expect(response.status).to eq(401)
  end

  it "uses custom renderer" do
    handle_request_exceptions do
      get "/rescue", headers: { "Accept" => "application/json" }
    end
    expect(response.status).to eq(401)
    expect(response.content_type).to eq("application/json")
    expect(JSON.parse(response.body)).to match(
      "errors" => [
        a_hash_including(
          "code" => "unauthorized",
          "status" => "401",
          "title" => "Unauthorized",
          "detail" => nil,
          "meta" => {
            "__details__" => a_hash_including(
              "exception" => a_string_including("StandardError"),
              "traces" => a_hash_including(
                "Application Trace" => an_instance_of(Array),
                "Framework Trace" => an_instance_of(Array)
              )
            )
          }
        )
      ]
    )
  end

  it "can render in Rails style" do
    handle_request_exceptions do
      get "/rescue/rails", headers: { "Accept" => "application/json" }
    end
    expect(response.status).to eq(403)
    expect(response.content_type).to eq("application/json")
    expect(JSON.parse(response.body)).to match(
      a_hash_including(
        "status" => 403,
        "error" => "Forbidden",
        "exception" => a_string_including("RailsError"),
        "traces" => a_hash_including(
          "Application Trace" => an_instance_of(Array),
          "Framework Trace" => an_instance_of(Array)
        )
      )
    )
  end

  context "public exceptions" do
    around do |example|
      show_detailed_exceptions(false) { example.run }
    end

    it "handles public exceptions for HTML requests" do
      handle_request_exceptions do
        get "/rescue"
      end

      expect(response.status).to eq(401)
      expect(response.content_type).to eq("text/html")
      expect(response.body).to include("You have to log in")
    end

    it "handles public exceptions for JSON requests" do
      handle_request_exceptions do
        get "/rescue", headers: { "Accept": "application/json" }
      end

      expect(response.status).to eq(401)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to include("Unauthorized")
    end

    it "renders HTML for public exceptions for non-castable types" do
      handle_request_exceptions do
        get "/rescue", headers: { "Accept": "image/png" }
      end

      expect(response.status).to eq(401)
      expect(response.content_type).to eq("text/html")
      expect(response.body).to include("You have to log in")
    end
  end
end
