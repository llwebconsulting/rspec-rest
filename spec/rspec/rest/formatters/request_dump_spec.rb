# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::Rest::Formatters::RequestDump do
  let(:response_struct) { Struct.new(:status, :headers, :body) }

  def build_dump(last_request:, response_headers:, response_body:, redacted_headers: nil)
    described_class.new(
      last_request: last_request,
      response: response_struct.new(200, response_headers, response_body),
      redacted_headers: redacted_headers
    ).format
  end

  def expect_default_redaction(dump)
    expect(dump).to include("Authorization: [REDACTED]")
    expect(dump).to include("Set-Cookie: [REDACTED]")
    expect(dump).to include("Accept: application/json")
    expect(dump).not_to include("Bearer secret")
    expect(dump).not_to include("top-secret")
  end

  def expect_custom_redaction(dump)
    expect(dump).to include("X-Custom-Secret: [REDACTED]")
    expect(dump).to include("Authorization: Bearer visible")
    expect(dump).not_to include("X-Custom-Secret: shh")
  end

  it "redacts sensitive headers by default" do
    dump = build_dump(
      last_request: {
        method: "GET",
        path: "/v1/users",
        headers: {
          "Authorization" => "Bearer secret",
          "Accept" => "application/json"
        },
        body: ""
      },
      response_headers: { "Set-Cookie" => "session=top-secret", "Content-Type" => "application/json" },
      response_body: '{"ok":true}'
    )

    expect_default_redaction(dump)
  end

  it "supports configurable header redaction list" do
    dump = build_dump(
      last_request: {
        method: "GET",
        path: "/v1/users",
        headers: {
          "X-Custom-Secret" => "shh",
          "Authorization" => "Bearer visible"
        },
        body: ""
      },
      response_headers: {},
      response_body: "",
      redacted_headers: ["X-Custom-Secret"]
    )

    expect_custom_redaction(dump)
  end
end
