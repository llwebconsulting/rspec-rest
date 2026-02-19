# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::Rest do
  include described_class

  it "raises a clear error when rest_response is called without a request context" do
    expect do
      rest_response
    end.to raise_error(
      RSpec::Rest::MissingRequestContextError,
      /No active REST request context/
    )
  end

  it "raises a clear error when last_request is called without a request context" do
    expect do
      last_request
    end.to raise_error(
      RSpec::Rest::MissingRequestContextError,
      /No active REST request context/
    )
  end

  api do
    app RackApp.new
    base_path "/v1"
    base_headers "Accept" => "application/json"
    default_format :json
  end

  resource "/users" do
    get "/" do
      expect_status 200
      expect_header "content-type", %r{application/json}
      expect_header "Content-Type", "application/json"
      expect_json array_of(hash_including("id" => integer, "email" => string))
      expect(last_request[:path]).to eq("/v1/users")
      expect(last_request[:headers]["Accept"]).to eq("application/json")
    end

    get "/{id}" do
      path_params id: 1
      query include_details: "true"
      expect_status 200
      expect(last_request[:path]).to eq("/v1/users/1?include_details=true")
    end

    get "/1" do
      expect_json(
        "id" => 1,
        "email" => "jane@example.com",
        "name" => "Jane"
      )
    end

    get "/1" do
      expect_json do |payload|
        expect(payload["id"]).to integer
        expect(payload["email"]).to string
      end
    end

    post "/" do
      headers "X-Trace-Id" => "dsl-123"
      header "X-Feature", "dsl"
      json "email" => "dsl@example.com", "name" => "DSL"
      expect_status 201
      expect_json hash_including("email" => "dsl@example.com", "id" => integer)
      expect(last_request[:headers]["X-Trace-Id"]).to eq("dsl-123")
      expect(last_request[:headers]["X-Feature"]).to eq("dsl")
      expect(last_request[:headers]["Content-Type"]).to eq("application/json")
    end

    resource "/{id}/posts" do
      get "/" do
        path_params id: 1
        expect(rest_response.status).to eq(404)
        expect(last_request[:path]).to eq("/v1/users/1/posts")
      end
    end

    get "/{id}" do
      # Intentionally set extra headers and path params in this example
      headers "X-Leaky-Header" => "should-not-persist"
      path_params id: 1

      expect(rest_response.status).to eq(200)
      expect(last_request[:path]).to eq("/v1/users/1")
      expect(last_request[:headers]["X-Leaky-Header"]).to eq("should-not-persist")
    end

    get "/" do
      # This example should not see headers or params from previous examples.
      expect(rest_response.status).to eq(200)
      expect(last_request[:path]).to eq("/v1/users")

      # Base headers should still be applied.
      expect(last_request[:headers]["Accept"]).to eq("application/json")

      # The transient header set in the previous example must not be present.
      expect(last_request[:headers].key?("X-Leaky-Header")).to be(false)
    end
  end

  resource "/flags" do
    get "/" do
      expect_status 200
      expect_json hash_including("enabled" => boolean)
    end
  end
end
