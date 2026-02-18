# frozen_string_literal: true

require "spec_helper"

# These examples are defined dynamically by the DSL verb macros (get/post/etc.),
# so static analysis cannot see literal `it` blocks in this file.
# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe RSpec::Rest do
  include described_class

  api do
    app RackApp.new
    base_path "/v1"
    base_headers "Accept" => "application/json"
    default_format :json
  end

  resource "/users" do
    get "/" do
      expect(rest_response.status).to eq(200)
      expect(rest_response.json).to be_an(Array)
      expect(last_request[:path]).to eq("/v1/users")
      expect(last_request[:headers]["Accept"]).to eq("application/json")
    end

    get "/{id}" do
      path_params id: 1
      query include_details: "true"
      expect(rest_response.status).to eq(200)
      expect(last_request[:path]).to eq("/v1/users/1?include_details=true")
    end

    post "/" do
      headers "X-Trace-Id" => "dsl-123"
      header "X-Feature", "dsl"
      json "email" => "dsl@example.com", "name" => "DSL"
      expect(rest_response.status).to eq(201)
      expect(rest_response.json["email"]).to eq("dsl@example.com")
      expect(last_request[:headers]["X-Trace-Id"]).to eq("dsl-123")
      expect(last_request[:headers]["X-Feature"]).to eq("dsl")
      expect(last_request[:headers]["Content-Type"]).to eq("application/json")
    end

    get "/leaky_state_example" do
      # Intentionally set extra headers and path params in this example
      headers "X-Leaky-Header" => "should-not-persist"
      path_params id: 42

      expect(rest_response.status).to eq(200)
      expect(last_request[:path]).to eq("/v1/users/42")
      expect(last_request[:headers]["X-Leaky-Header"]).to eq("should-not-persist")
    end

    get "/isolation_check" do
      # This example should not see headers or params from previous examples.
      expect(rest_response.status).to eq(200)
      expect(last_request[:path]).to eq("/v1/users/isolation_check")

      # Base headers should still be applied.
      expect(last_request[:headers]["Accept"]).to eq("application/json")

      # The transient header set in the previous example must not be present.
      expect(last_request[:headers].key?("X-Leaky-Header")).to be(false)
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
