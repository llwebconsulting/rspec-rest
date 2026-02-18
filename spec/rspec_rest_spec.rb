# frozen_string_literal: true

require "stringio"
require "spec_helper"

RSpec.describe RSpec::Rest do
  def call_app(app, method:, path:, body: nil, content_type: "application/json")
    env = {
      "REQUEST_METHOD" => method,
      "PATH_INFO" => path,
      "rack.input" => StringIO.new(body.to_s)
    }
    env["CONTENT_TYPE"] = content_type if body

    app.call(env)
  end

  it "has a version number" do
    expect(RSpec::Rest::VERSION).not_to be_nil
  end

  it "returns users from GET /v1/users" do
    app = RackApp.new
    status, headers, body = call_app(app, method: "GET", path: "/v1/users")

    expect(status).to eq(200)
    expect(headers["Content-Type"]).to eq("application/json")

    parsed = JSON.parse(body.join)
    expect(parsed).to be_an(Array)
    expect(parsed).not_to be_empty
  end

  it "creates a user with POST /v1/users" do
    app = RackApp.new
    payload = JSON.dump({ "email" => "carl@example.com", "name" => "Carl" })

    status, headers, body = call_app(app, method: "POST", path: "/v1/users", body: payload)

    expect(status).to eq(201)
    expect(headers["Content-Type"]).to eq("application/json")
    parsed = JSON.parse(body.join)
    expect(parsed["id"]).to eq(3)
    expect(parsed["email"]).to eq("carl@example.com")
  end

  it "returns a single user from GET /v1/users/:id" do
    app = RackApp.new
    status, _headers, body = call_app(app, method: "GET", path: "/v1/users/1")

    expect(status).to eq(200)
    parsed = JSON.parse(body.join)
    expect(parsed["id"]).to eq(1)
    expect(parsed["email"]).to eq("jane@example.com")
  end

  it "returns non-json body from GET /v1/bad_json" do
    app = RackApp.new
    status, headers, body = call_app(app, method: "GET", path: "/v1/bad_json")

    expect(status).to eq(200)
    expect(headers["Content-Type"]).to eq("text/plain")
    expect(body.join).to eq("this is not json")
  end
end
