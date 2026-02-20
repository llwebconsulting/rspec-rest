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
      "Authorization" => "Bearer acceptance-secret"
    )
    default_format :json
    base_url "http://localhost:3000"
  end

  resource "/users" do
    get "/" do
      expect_status 200
      expect_header "Content-Type", "application/json"
      expect_json array_of(hash_including("id" => integer, "email" => string))
    end

    post "/" do
      json "email" => "acceptance@example.com", "name" => "Acceptance"
      expect_status 201
      capture :user_id, "$.id"
      expect(get(:user_id)).to integer

      # Multi-step flow in the same example: use captured id in follow-up request.
      start_rest_request(method: :get, path: "/{id}", resource_path: "/users")
      path_params id: get(:user_id)
      expect_status 200
      expect_json hash_including("id" => get(:user_id))
    end
  end

  resource "/users" do
    get "/" do
      expect do
        expect_status 201
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("Request:")
        expect(error.message).to include("Response:")
        expect(error.message).to include("Reproduce with:")
        expect(error.message).to include("curl -X GET")
        expect(error.message).to include("'http://localhost:3000/v1/users'")
        expect(error.message).to include("Authorization: [REDACTED]")
      }
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
