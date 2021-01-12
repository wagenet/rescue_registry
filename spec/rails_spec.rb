begin
  require "rails"
rescue LoadError
end

if defined?(Rails)
  require_relative "rails_helper"

  RSpec.describe "Rails App Usage", type: :request do
    around do |example|
      handle_request_exceptions { example.run }
    end

    def make_request(exception, accept: nil, format: nil)
      get "/rescue", params: { exception: exception, format: format }, headers: { "Accept" => accept && Mime[accept] }
    end

    it "set status code" do
      make_request("CustomStatusError")
      expect(response.status).to eq(401)
    end

    it "uses custom renderer" do
      make_request("CustomStatusError", accept: :json)
      expect(response.status).to eq(401)
      expect(response.content_type).to start_with("application/json")
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
      make_request("CustomTitleError", accept: :json)
      expect(response.status).to eq(500)
      expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("My Title")
    end

    context "changing the detail" do
      it "can change to the exception message" do
        make_request("DetailExceptionError", accept: :json)
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body)["errors"][0]["detail"]).to eq("Exception in #index")
      end

      it "can change to a proc" do
        make_request("DetailProcError", accept: :json)
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body)["errors"][0]["detail"]).to eq("RESCUECONTROLLER::DETAILPROCERROR")
      end

      it "can change to a string" do
        make_request("DetailStringError", accept: :json)
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body)["errors"][0]["detail"]).to eq("Custom Detail")
      end
    end

    it "changing the meta" do
      make_request("MetaProcError", accept: :json)
      expect(response.status).to eq(500)
      expect(JSON.parse(response.body)["errors"][0]["meta"]).to match(a_hash_including("class_name" => "RESCUECONTROLLER::METAPROCERROR"))
    end

    it "can use custom handlers" do
      make_request("CustomHandlerError", accept: :json)
      expect(response.status).to eq(302)
      expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Custom Title")
    end

    it "can render in Rails style" do
      make_request("RailsError", accept: :json)
      expect(response.status).to eq(403)
      expect(response.content_type).to start_with("application/json")
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
      make_request("SubclassedError")
      expect(response.status).to eq(401)
    end

    it "can do a status passthrough" do
      make_request("::ActiveRecord::RecordNotFound", accept: :jsonapi)
      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)["errors"][0]["code"]).to eq("not_found")

      make_request("::ActiveRecord::StaleObjectError", accept: :jsonapi)
      expect(response.status).to eq(409), "has correct status for multiple errors"
      expect(JSON.parse(response.body)["errors"][0]["code"]).to eq("conflict")
    end

    it "falls back to global handler" do
      make_request("::GlobalError", accept: :json)
      expect(response.status).to eq(400)
    end

    it "doesn't pollute parent contexts" do
      make_request("::OtherGlobalError")
      expect(response.status).to eq(401), "affects registered context"

      get "/other"
      expect(response.status).to eq(500), "does not affect parent context"
    end

    context "public exceptions" do
      around do |example|
        show_detailed_exceptions(false) { example.run }
      end

      it "handles public exceptions for HTML requests" do
        make_request("CustomStatusError")

        expect(response.status).to eq(401)
        expect(response.content_type).to start_with("text/html")
        expect(response.body).to include("You have to log in")
      end

      it "handles public exceptions for JSON requests" do
        make_request("CustomStatusError", accept: :json)

        expect(response.status).to eq(401)
        expect(response.content_type).to start_with("application/json")
        expect(response.body).to include("Unauthorized")
      end

      it "handles public exceptions for JSON:API requests" do
        make_request("CustomStatusError", accept: :jsonapi)

        expect(response.status).to eq(401)
        expect(response.content_type).to start_with("application/vnd.api+json")
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq("unauthorized")
      end

      it "renders HTML for public exceptions for non-castable types" do
        make_request("CustomStatusError", accept: :png)

        expect(response.status).to eq(401)
        expect(response.content_type).to start_with("text/html")
        expect(response.body).to include("You have to log in")
      end

      it "handles unknown format types" do
        make_request("CustomStatusError", accept: :json, format: "invalid")
        expect(response.status).to eq(401)
      end

      it "passes unhandled errors to default handler" do
        make_request("StandardError", accept: :json, format: "invalid")
        expect(response.status).to eq(500)
        expect(response.body).to include("We're sorry, but something went wrong (500)"), "has standard Rails error message"
      end
    end
  end
end
