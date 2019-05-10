require_relative "rails_helper"

RSpec.describe "basic behavior", type: :request do
  around do |example|
    handle_request_exceptions { example.run }
  end

  it "set status code" do
    get "/rescue", params: { exception: "CustomStatusError" }
    expect(response.status).to eq(401)
  end

  it "uses custom renderer" do
    get "/rescue", params: { exception: "CustomStatusError" }, headers: { "Accept" => "application/json" }
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
              "exception" => a_string_including("CustomStatusError"),
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

  it "can change the title" do
    get "/rescue", params: { exception: "CustomTitleError" }, headers: { "Accept" => "application/json" }
    expect(response.status).to eq(500)
    expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("My Title")
  end

  it "can render in Rails style" do
    get "/rescue", params: { exception: "RailsError" }, headers: { "Accept" => "application/json" }
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

  # TODO: Add more robust checks for this
  it "handles subclasses" do
    get "/rescue", params: { exception: "SubclassedError" }
    expect(response.status).to eq(401)
  end

  context "public exceptions" do
    around do |example|
      show_detailed_exceptions(false) { example.run }
    end

    it "handles public exceptions for HTML requests" do
      get "/rescue", params: { exception: "CustomStatusError" }

      expect(response.status).to eq(401)
      expect(response.content_type).to eq("text/html")
      expect(response.body).to include("You have to log in")
    end

    it "handles public exceptions for JSON requests" do
      get "/rescue", params: { exception: "CustomStatusError" }, headers: { "Accept": "application/json" }

      expect(response.status).to eq(401)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to include("Unauthorized")
    end

    it "renders HTML for public exceptions for non-castable types" do
      get "/rescue", params: { exception: "CustomStatusError" }, headers: { "Accept": "image/png" }

      expect(response.status).to eq(401)
      expect(response.content_type).to eq("text/html")
      expect(response.body).to include("You have to log in")
    end
  end
end
