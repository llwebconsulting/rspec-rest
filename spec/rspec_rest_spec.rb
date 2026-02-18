# frozen_string_literal: true

require "stringio"
require "spec_helper"

RSpec.describe RSpec::Rest do
  it "has a version number" do
    expect(RSpec::Rest::VERSION).not_to be_nil
  end

  it "successfully makes a GET request to the test Rack app and returns JSON" do
    app = RackApp.new
    status, headers, body = app.call(
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/v1/users",
      "rack.input" => StringIO.new
    )

    expect(status).to eq(200)
    expect(headers["Content-Type"]).to eq("application/json")

    parsed = JSON.parse(body.join)
    expect(parsed).to be_an(Array)
    expect(parsed).not_to be_empty
  end
end
