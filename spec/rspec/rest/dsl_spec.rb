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

  it "raises a clear error when contract name is nil" do
    expect do
      self.class.contract(nil) { hash_including("id" => integer) }
    end.to raise_error(ArgumentError, /contract name cannot be nil/)
  end

  it "raises a clear error when contract name cannot be symbolized" do
    invalid_name = Object.new

    expect do
      self.class.contract(invalid_name) { hash_including("id" => integer) }
    end.to raise_error(ArgumentError, /must respond to #to_sym/)
  end

  it "raises when both positional and keyword paths are provided" do
    expect do
      self.class.get("/", path: "/users")
    end.to raise_error(ArgumentError, /received both positional and keyword paths/)
  end

  it "raises when no path is provided" do
    expect do
      self.class.get(description: "missing path")
    end.to raise_error(ArgumentError, /requires a request path/)
  end

  it "raises when both positional and keyword descriptions are provided" do
    expect do
      self.class.get("/", "old style", description: "new style")
    end.to raise_error(ArgumentError, /received both positional and keyword descriptions/)
  end

  it "emits a deprecation warning for positional request paths" do
    allow(RSpec::Rest::Deprecation).to receive(:warn)

    self.class.send(:warn_on_deprecated_positional_path, :get)

    expect(RSpec::Rest::Deprecation).to have_received(:warn).with(
      hash_including(
        key: :verb_positional_path,
        message: %r{get\("/users"\).*Rails/HttpPositionalArguments}m
      )
    )
  end

  it "emits a deprecation warning for positional request descriptions" do
    allow(RSpec::Rest::Deprecation).to receive(:warn)

    self.class.send(:warn_on_deprecated_positional_description, :get)

    expect(RSpec::Rest::Deprecation).to have_received(:warn).with(
      hash_including(
        key: :verb_positional_description,
        message: %r{get\(path, description\).*Rails/HttpPositionalArguments}m
      )
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

  with_headers "X-Global" => "global"
  with_query locale: "en"

  contract :user_summary do
    hash_including("id" => integer, "email" => string, "name" => string)
  end

  contract :flag_payload do
    { "enabled" => true }
  end

  contract :post_summary do
    hash_including(
      "id" => integer,
      "title" => string,
      "author" => hash_including("id" => integer)
    )
  end

  it "marks expect_json_contract as deprecated" do
    allow(RSpec::Rest::Deprecation).to receive(:warn)

    expect_json_contract(:user_summary)

    expect(RSpec::Rest::Deprecation).to have_received(:warn).with(
      hash_including(
        key: :expect_json_contract,
        message: /deprecated/
      )
    )
  end

  it "does not mark contract(:name) lookup as deprecated" do
    allow(RSpec::Rest::Deprecation).to receive(:warn)

    contract(:user_summary)

    expect(RSpec::Rest::Deprecation).not_to have_received(:warn)
  end

  it "raises when contract lookup receives a block in example context" do
    expect do
      contract(:inline) { hash_including("id" => integer) }
    end.to raise_error(ArgumentError, /does not accept a block/)
  end

  it "supports scalar value overrides with contract_with" do
    payload = {
      "id" => 1,
      "title" => "My Title",
      "author" => { "id" => 1, "name" => "Carl" },
      "metadata" => { "ignored" => true }
    }

    expect(payload).to contract_with(:post_summary, id: 1, title: "My Title")
  end

  it "supports nested overrides with contract_with" do
    payload = {
      "id" => 1,
      "title" => "My Title",
      "author" => { "id" => 7, "name" => "Carl" }
    }

    expect(payload).to contract_with(:post_summary, author: { id: 7 })
  end

  it "supports matcher-valued overrides with contract_with" do
    payload = {
      "id" => 1,
      "title" => "My Title",
      "author" => { "id" => 9, "name" => "Carl" }
    }

    expect(payload).to contract_with(:post_summary, title: a_string_matching(/\AMy/))
  end

  it "supports array composition with contract_with" do
    payload = [
      { "id" => 1, "title" => "My Title", "author" => { "id" => 1 } },
      { "id" => 2, "title" => "My Title", "author" => { "id" => 2 } }
    ]

    expect(payload).to array_of(contract_with(:post_summary, title: "My Title"))
  end

  it "raises a clear failure for unknown override keys" do
    payload = {
      "id" => 1,
      "title" => "My Title",
      "author" => { "id" => 1 }
    }

    expect do
      expect(payload).to contract_with(:post_summary, missing: true)
    end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /Unknown override key "missing"/)
  end

  it "raises when both positional and keyword overrides are provided" do
    payload = {
      "id" => 1,
      "title" => "My Title",
      "author" => { "id" => 1 }
    }

    expect do
      expect(payload).to contract_with(:post_summary, { title: "One" }, title: "Two")
    end.to raise_error(ArgumentError, /both positional Hash and keyword overrides/)
  end

  it "raises when overrides is not a Hash" do
    payload = {
      "id" => 1,
      "title" => "My Title",
      "author" => { "id" => 1 }
    }

    expect do
      expect(payload).to contract_with(:post_summary, 123)
    end.to raise_error(ArgumentError, /requires overrides to be a Hash/)
  end

  it "raises a clear failure for nested overrides under a scalar key" do
    payload = {
      "id" => 1,
      "title" => "My Title",
      "author" => { "id" => 1 }
    }

    expect do
      expect(payload).to contract_with(:post_summary, title: { new: "Title" })
    end.to raise_error(
      RSpec::Expectations::ExpectationNotMetError,
      /does not support nested overrides/
    )
  end

  resource "/users" do
    with_headers "X-Resource" => "users"
    with_query include_details: "true"
    with_auth "resource-token"

    get path: "/", description: "  returns users collection  " do
      expect_status 200
      expect_header "content-type", %r{application/json}
      expect_header "Content-Type", "application/json"
      expect_json array_of(contract(:user_summary))
      expect_json_first hash_including("id" => integer)
      expect_json_item 1, hash_including("id" => 2)
      expect_json_last hash_including("id" => integer, "email" => string)
      expect(last_request[:path]).to include("/v1/users?")
      expect(last_request[:headers]["Accept"]).to eq("application/json")
      expect(last_request[:headers]["Authorization"]).to eq("Bearer resource-token")
      expect(last_request[:headers]["X-Global"]).to eq("global")
      expect(last_request[:headers]["X-Resource"]).to eq("users")
      expect(last_request[:path]).to include("locale=en")
      expect(last_request[:path]).to include("include_details=true")
    end

    get "/", "supports positional descriptions temporarily" do
      expect_status 200
    end

    get "/{id}" do
      path_params id: 1
      query include_details: "true", locale: "fr"
      expect_status 200
      expect(last_request[:path]).to include("/v1/users/1?")
      expect(last_request[:path]).to include("locale=fr")
      expect(last_request[:path]).to include("include_details=true")
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
      expect_json_at(:email, "alex@example.com")
      expect_json_at("name", "Alex")
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

    get "/1" do
      expect do
        expect_json_at("author.id")
      end.to raise_error(
        RSpec::Rest::InvalidJsonSelectorError,
        /Top-level shorthand accepts Symbol or simple String keys/
      )
    end

    get "/1" do
      expect do
        expect_json_at(123)
      end.to raise_error(
        RSpec::Rest::InvalidJsonSelectorError,
        /Selector must be a Symbol, a String top-level key, or a JSONPath String/
      )
    end

    get "/" do
      expect do
        expect_json_item(99)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /out of bounds/)
    end

    get "/" do
      expect do
        expect_json_item("0")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /index to be an Integer/)
    end

    get "/1" do
      expect do
        expect_json contract(:missing_contract)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /Unknown contract/)
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
      with_headers "X-Nested" => "nested"
      with_query page: 2

      get "/" do
        path_params id: 1
        expect(rest_response.status).to eq(404)
        expect(last_request[:path]).to include("/v1/users/1/posts?")
        expect(last_request[:path]).to include("locale=en")
        expect(last_request[:path]).to include("include_details=true")
        expect(last_request[:path]).to include("page=2")
        expect(last_request[:headers]["X-Nested"]).to eq("nested")
        expect(last_request[:headers]["X-Resource"]).to eq("users")
      end
    end

    get "/{id}" do
      # Intentionally set extra headers and path params in this example
      headers "X-Leaky-Header" => "should-not-persist"
      path_params id: 1

      expect(rest_response.status).to eq(200)
      expect(last_request[:path]).to include("/v1/users/1?")
      expect(last_request[:path]).to include("locale=en")
      expect(last_request[:path]).to include("include_details=true")
      expect(last_request[:headers]["X-Leaky-Header"]).to eq("should-not-persist")
    end

    get "/" do
      # This example should not see headers or params from previous examples.
      expect(rest_response.status).to eq(200)
      expect(last_request[:path]).to include("/v1/users?")
      expect(last_request[:path]).to include("locale=en")
      expect(last_request[:path]).to include("include_details=true")

      # Base headers should still be applied.
      expect(last_request[:headers]["Accept"]).to eq("application/json")

      # The transient header set in the previous example must not be present.
      expect(last_request[:headers].key?("X-Leaky-Header")).to be(false)
    end
  end

  resource "/flags" do
    get "/" do
      expect_status 200
      expect_json contract(:flag_payload)
    end

    get "/" do
      expect do
        expect_json_first
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /payload to be an Array/)
    end
  end

  resource "/errors" do
    get "/string" do
      expect_error status: 422, message: "Unable to save post"
    end

    get "/string" do
      expect_error status: 422, message: "Unable to save post", key: :error
    end

    get "/array" do
      expect_error status: 422, includes: "font_size", field: "font_size"
    end

    get "/list" do
      expect do
        expect_error status: 422, message: "anything"
      end.to raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        /Expected JSON response to be an object/
      )
    end
  end

  resource "/bad_json" do
    get "" do
      expect_status 200
      expect_body_includes "not json"
      expect_body_matches(/this is not json/)
      expect_body_matches "this is not json"
    end

    get "" do
      expect do
        expect_body_matches(123)
      end.to raise_error(ArgumentError, /requires a String or Regexp pattern/)
    end

    get "" do
      expect do
        expect_body_includes(123)
      end.to raise_error(ArgumentError, /requires a String fragment/)
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

  resource "/uploads" do
    post "/" do
      multipart!
      file_path = File.expand_path("../../fixtures/files/sample_upload.txt", __dir__)
      file :file, file_path, content_type: "text/plain"

      expect_status 201
      expect_json hash_including(
        "filename" => "sample_upload.txt",
        "content_type" => "text/plain",
        "size" => integer
      )
      expect(last_request[:headers].key?("Content-Type")).to be(false)
      expect(last_request[:body][:file]).to be_a(Rack::Test::UploadedFile)
    end

    post "/" do
      uploaded = Rack::Test::UploadedFile.new(
        File.expand_path("../../fixtures/files/sample_upload.txt", __dir__),
        "text/plain"
      )
      file :file, uploaded

      expect_status 201
      expect_json hash_including("filename" => "sample_upload.txt")
    end

    post "/" do
      uploaded = Rack::Test::UploadedFile.new(
        File.expand_path("../../fixtures/files/sample_upload.txt", __dir__),
        "text/plain"
      )

      expect do
        file :file, uploaded, content_type: "image/jpeg"
      end.to raise_error(
        ArgumentError,
        /content_type and filename cannot be specified/
      )
    end

    post "/" do
      multipart!
      json note: "invalid"

      expect do
        rest_response
      end.to raise_error(ArgumentError, /Cannot use json\(\.\.\.\) with multipart! requests/)
    end
  end

  it "builds full-path example names and supports optional descriptions" do
    descriptions = self.class.examples.map(&:description)

    expect(descriptions).to include("GET /v1/users - returns users collection")
    expect(descriptions).to include("GET /v1/users/{id}")
    expect(descriptions).to include("GET /v1/users/{id}/posts")
  end
end
