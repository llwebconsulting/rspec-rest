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
    base_headers(
      "Accept" => "application/json",
      "Authorization" => "Bearer base-token"
    )
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
      expect(last_request[:headers]["Authorization"]).to eq("Bearer base-token")
    end

    get "/{id}" do
      path_params id: 1
      query include_details: "true"
      expect_status 200
      expect(last_request[:path]).to eq("/v1/users/1?include_details=true")
    end

    get "/{id}" do
      path_params id: 1
      expect_json(
        "id" => 1,
        "email" => "jane@example.com",
        "name" => "Jane"
      )
    end

    get "/{id}" do
      path_params id: 2
      expect_json do |payload|
        expect(payload["id"]).to integer
        expect(payload["email"]).to string
      end
    end

    get "/{id}" do
      path_params id: 2
      expect_json_at("$.email", "alex@example.com")
      expect_json_at("$.id", integer)
      expect_json_at("$.name") do |value|
        expect(value).to eq("Alex")
      end
    end

    post "/" do
      headers "X-Trace-Id" => "dsl-123"
      header "X-Feature", "dsl"
      json "email" => "dsl@example.com", "name" => "DSL"
      expect_status 201
      expect_json hash_including("email" => "dsl@example.com", "id" => integer)
      capture :user_id, "$.id"
      expect(get(:user_id)).to integer
      expect(last_request[:headers]["X-Trace-Id"]).to eq("dsl-123")
      expect(last_request[:headers]["X-Feature"]).to eq("dsl")
      expect(last_request[:headers]["Content-Type"]).to eq("application/json")
    end

    post "/" do
      json "email" => "flow@example.com", "name" => "Flow"
      expect_status 201
      capture :user_id, "$.id"

      start_rest_request(method: :get, path: "/{user_id}", resource_path: "/users")
      path_params user_id: get(:user_id)
      expect_status 200
      expect_json hash_including("id" => get(:user_id))
    end

    get "/1" do
      expect do
        get(:missing_id)
      end.to raise_error(RSpec::Rest::MissingCaptureError, /No captured value found/)
    end

    get "/1" do
      expect do
        capture :broken, "users[0]"
      end.to raise_error(RSpec::Rest::InvalidJsonSelectorError, /must start with '\$'/)
    end

    get "/1" do
      expect do
        capture :missing, "$.not_here"
      end.to raise_error(RSpec::Rest::MissingJsonPathError, /did not match path segment/)
    end

    get "/1" do
      expect do
        expect_json_at("$.not_here")
      end.to raise_error(RSpec::Rest::MissingJsonPathError, /did not match path segment/)
    end

    get "/" do
      bearer "token-123"
      expect_status 200
      expect(last_request[:headers]["Authorization"]).to eq("Bearer token-123")
    end

    get "/" do
      bearer "token-123"
      unauthenticated!
      expect_status 200
      expect(last_request[:headers].key?("Authorization")).to be(false)
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

  resource "/errors" do
    get "/string" do
      expect_error status: 422, message: "Unable to save post"
    end

    get "/array" do
      expect_error status: 422, includes: "font_size", field: "font_size"
    end
  end

  resource "/posts" do
    get "/" do
      query page: 1, per_page: 2
      expect_status 200
      expect_page_size 2
      expect_max_page_size 20
      expect_ids_in_order [3, 2]
    end

    get "/" do
      query per_page: 25
      expect_status 200
      expect_page_size 3
      expect_max_page_size 20
    end
  end
end
