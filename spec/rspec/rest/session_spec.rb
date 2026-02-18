# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::Rest::Session do
  describe "#request" do
    it "performs a GET request and parses JSON through Response#json" do
      config = RSpec::Rest::Config.new(app: RackApp.new)
      session = described_class.new(config)

      response = session.request(method: :get, path: "/v1/users")

      expect(response).to be_a(RSpec::Rest::Response)
      expect(response.status).to eq(200)
      expect(response.json).to be_a(Array)
      expect(response.json.first).to include("id", "email", "name")
    end

    it "raises InvalidJsonError with a body snippet for invalid JSON responses" do
      config = RSpec::Rest::Config.new(app: RackApp.new)
      session = described_class.new(config)

      response = session.request(method: :get, path: "/v1/bad_json")

      expect do
        response.json
      end.to raise_error(RSpec::Rest::InvalidJsonError, /Body snippet: "this is not json"/)
    end

    it "builds paths from base path, resource path, and endpoint path" do
      config = RSpec::Rest::Config.new(app: RackApp.new, base_path: "/v1")
      session = described_class.new(config)

      response = session.request(method: :get, resource_path: "/users", path: "/")

      expect(response.status).to eq(200)
      expect(session.last_request[:path]).to eq("/v1/users")
    end

    it "applies base headers and JSON content type for JSON payloads" do
      config = RSpec::Rest::Config.new(
        app: RackApp.new,
        base_headers: { "Accept" => "application/json" }
      )
      session = described_class.new(config)

      response = session.request(
        method: :post,
        path: "/v1/users",
        json: { "email" => "milestone1@example.com", "name" => "Milestone" }
      )

      expect(response.status).to eq(201)
      expect(response.json["email"]).to eq("milestone1@example.com")
      expect(session.last_request[:headers]["Accept"]).to eq("application/json")
      expect(session.last_request[:headers]["Content-Type"]).to eq("application/json")
    end
  end

  describe "initialization" do
    it "raises MissingAppError when config.app is missing" do
      config = RSpec::Rest::Config.new

      expect do
        described_class.new(config)
      end.to raise_error(RSpec::Rest::MissingAppError, /Config#app is required/)
    end
  end
end
