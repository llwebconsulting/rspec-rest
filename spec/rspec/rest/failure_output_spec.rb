# frozen_string_literal: true

require "spec_helper"

# This group defines examples dynamically via DSL verb macros (get/post/etc.).
# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe RSpec::Rest do
  include described_class

  api do
    app RackApp.new
    base_path "/v1"
    base_headers(
      "Accept" => "application/json",
      "Authorization" => "Bearer super-secret-token"
    )
    default_format :json
  end

  contract :strict_user do
    hash_including("id" => 999)
  end

  resource "/users" do
    get "/" do
      expect do
        expect_status 201
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/users")
        expect(error.message).to include("Authorization: [REDACTED]")
        expect(error.message).not_to include("super-secret-token")
        expect(error.message).to include("Response:")
        expect(error.message).to include("Status: 200")
        expect(error.message).to include("\"id\": 1")
        expect(error.message).to include("Reproduce with:")
        expect(error.message).to include("curl -X GET")
        expect(error.message).to include("'http://example.org/v1/users'")
        expect(error.message).to include("-H 'Authorization: [REDACTED]'")
      }
    end

    post "/" do
      headers "X-Trace-Id" => "trace-123"
      query include_details: "true"
      json "email" => "dump@example.com", "name" => "Dump"

      expect do
        expect_header("X-Trace-Id", "missing")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Expected response header \"X-Trace-Id\" to be present")
        expect(error.message).to include("Request:")
        expect(error.message).to include("POST /v1/users")
        expect(error.message).to include("\"email\": \"dump@example.com\"")
        expect(error.message).to include("Response:")
        expect(error.message).to include("Status: 201")
        expect(error.message).to include("curl -X POST")
        expect(error.message).to include("'http://example.org/v1/users?include_details=true'")
        expect(error.message).to include("-H 'X-Trace-Id: trace-123'")
        expect(error.message).to include("-d '{\"email\":\"dump@example.com\",\"name\":\"Dump\"}'")
      }
    end

    get "/" do
      expect do
        expect_json_at("$[0].id", 999)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/users")
        expect(error.message).to include("Response:")
        expect(error.message).to include("Status: 200")
        expect(error.message).to include("Reproduce with:")
        expect(error.message).to include("curl -X GET")
      }
    end

    get "/" do
      expect do
        expect_json_first("not-user")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/users")
        expect(error.message).to include("Response:")
        expect(error.message).to include("Reproduce with:")
      }
    end

    get "/" do
      expect do
        expect_json_item("0")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("index to be an Integer")
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/users")
        expect(error.message).to include("Reproduce with:")
      }
    end

    get "/" do
      expect do
        expect_json array_of(expect_json_contract(:strict_user))
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Contract :strict_user failed")
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/users")
        expect(error.message).to include("Reproduce with:")
      }
    end

    get "/" do
      expect do
        expect_json array_of(expect_json_contract(nil))
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Invalid contract name")
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/users")
        expect(error.message).to include("Reproduce with:")
      }
    end

    get "/" do
      expect do
        expect_ids_in_order([1, 2], selector: "$[*].missing_id")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("did not match element")
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/users")
        expect(error.message).to include("Reproduce with:")
        expect(error.message).to include("curl -X GET")
      }
    end
  end

  resource "/errors" do
    get "/string" do
      expect do
        expect_error(status: 422, includes: "font_size")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Request:")
        expect(error.message).to include("GET /v1/errors/string")
        expect(error.message).to include("Response:")
        expect(error.message).to include("Status: 422")
        expect(error.message).to include("Reproduce with:")
        expect(error.message).to include("curl -X GET")
      }
    end
  end

  resource "/posts" do
    get "/" do
      query page: 1, per_page: 2

      expect do
        expect_page_size(3)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("expected: 3")
        expect(error.message).to include("GET /v1/posts?page=1&per_page=2")
        expect(error.message).to include("Reproduce with:")
      }
    end

    get "/" do
      expect do
        expect_ids_in_order([1, 2, 3])
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("expected: [1, 2, 3]")
        expect(error.message).to include("GET /v1/posts")
        expect(error.message).to include("Reproduce with:")
      }
    end
  end

  resource "/flags" do
    get "/" do
      expect do
        expect_page_size(1, selector: "$.enabled")
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("resolve to an Array")
        expect(error.message).to include("GET /v1/flags")
        expect(error.message).to include("Reproduce with:")
      }
    end
  end

  resource "/uploads" do
    post "/" do
      file :file, File.expand_path("../../fixtures/files/sample_upload.txt", __dir__), content_type: "text/plain"

      expect do
        expect_status 200
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("POST /v1/uploads")
        expect(error.message).to include("Reproduce with:")
        expect(error.message).to include("curl -X POST")
      }
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
