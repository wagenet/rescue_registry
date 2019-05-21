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

    def make_request(exception, accept = nil)
      get "/rescue", params: { exception: exception }, headers: { "Accept" => accept && Mime[accept] }
    end

    it "set status code" do
      make_request("CustomStatusError")
      expect(response.status).to eq(401)
    end

    it "uses custom renderer" do
      make_request("CustomStatusError", :json)
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
      make_request("CustomTitleError", :json)
      expect(response.status).to eq(500)
      expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("My Title")
    end

    context "changing the detail" do
      it "can change to the exception message" do
        make_request("DetailExceptionError", :json)
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body)["errors"][0]["detail"]).to eq("Exception in #index")
      end

      it "can change to a proc" do
        make_request("DetailProcError", :json)
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body)["errors"][0]["detail"]).to eq("RESCUECONTROLLER::DETAILPROCERROR")
      end

      it "can change to a string" do
        make_request("DetailStringError", :json)
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body)["errors"][0]["detail"]).to eq("Custom Detail")
      end
    end

    it "changing the meta" do
      make_request("MetaProcError", :json)
      expect(response.status).to eq(500)
      expect(JSON.parse(response.body)["errors"][0]["meta"]).to match(a_hash_including("class_name" => "RESCUECONTROLLER::METAPROCERROR"))
    end

    it "can use custom handlers" do
      make_request("CustomHandlerError", :json)
      expect(response.status).to eq(302)
      expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("Custom Title")
    end

    it "can render in Rails style" do
      make_request("RailsError", :json)
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
      make_request("SubclassedError")
      expect(response.status).to eq(401)
    end

    it "can do a status passthrough" do
      make_request("::ActiveRecord::RecordNotFound", :jsonapi)
      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)["errors"][0]["code"]).to eq("not_found")
    end

    it "falls back to global handler" do
      make_request("::GlobalError", :json)
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
        expect(response.content_type).to eq("text/html")
        expect(response.body).to include("You have to log in")
      end

      it "handles public exceptions for JSON requests" do
        make_request("CustomStatusError", :json)

        expect(response.status).to eq(401)
        expect(response.content_type).to eq("application/json")
        expect(response.body).to include("Unauthorized")
      end

      it "handles public exceptions for JSON:API requests" do
        make_request("CustomStatusError", :jsonapi)

        expect(response.status).to eq(401)
        expect(response.content_type).to eq("application/vnd.api+json")
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq("unauthorized")
      end

      it "renders HTML for public exceptions for non-castable types" do
        make_request("CustomStatusError", :png)

        expect(response.status).to eq(401)
        expect(response.content_type).to eq("text/html")
        expect(response.body).to include("You have to log in")
      end
    end
  end
end
