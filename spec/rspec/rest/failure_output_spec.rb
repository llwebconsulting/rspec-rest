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
      }
    end

    post "/" do
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
      }
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
