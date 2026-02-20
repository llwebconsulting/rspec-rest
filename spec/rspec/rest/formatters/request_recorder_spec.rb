# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::Rest::Formatters::RequestRecorder do
  def base_post_request
    {
      method: "POST",
      url: "http://example.org/v1/users?include_details=true",
      headers: {
        "Content-Type" => "application/json",
        "X-Trace-Id" => "trace-123"
      },
      body: '{"email":"a@example.com"}'
    }
  end

  def expect_post_curl(curl)
    expect(curl).to include("curl -X POST")
    expect(curl).to include("'http://example.org/v1/users?include_details=true'")
    expect(curl).to include("-H 'Content-Type: application/json'")
    expect(curl).to include("-H 'X-Trace-Id: trace-123'")
    expect(curl).to include("-d '{\"email\":\"a@example.com\"}'")
  end

  it "builds curl with method, url, headers, and body" do
    curl = described_class.new(last_request: base_post_request).to_curl
    expect_post_curl(curl)
  end

  it "redacts sensitive headers by default" do
    curl = described_class.new(
      last_request: {
        method: "GET",
        url: "http://example.org/v1/users",
        headers: {
          "Authorization" => "Bearer secret"
        },
        body: nil
      }
    ).to_curl

    expect(curl).to include("-H 'Authorization: [REDACTED]'")
    expect(curl).not_to include("Bearer secret")
  end

  it "supports custom redaction lists" do
    curl = described_class.new(
      last_request: {
        method: "GET",
        url: "http://example.org/v1/users",
        headers: {
          "X-Custom-Secret" => "token123",
          "Authorization" => "Bearer visible"
        },
        body: nil
      },
      redacted_headers: ["X-Custom-Secret"]
    ).to_curl

    expect(curl).to include("-H 'X-Custom-Secret: [REDACTED]'")
    expect(curl).to include("-H 'Authorization: Bearer visible'")
  end
end
