# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::Rest::JsonSelector do
  describe ".extract" do
    let(:json) do
      {
        "id" => 42,
        "user" => {
          "email" => "selector@example.com"
        },
        "items" => [
          { "id" => 1, "name" => "first" },
          { "id" => 2, "name" => "second" }
        ]
      }
    end

    it "extracts nested hash values with dot notation" do
      expect(described_class.extract(json, "$.user.email")).to eq("selector@example.com")
    end

    it "extracts array values with index notation" do
      expect(described_class.extract(json, "$.items[1].id")).to eq(2)
    end

    it "raises clear error for invalid selector syntax" do
      expect do
        described_class.extract(json, "items[0].id")
      end.to raise_error(RSpec::Rest::InvalidJsonSelectorError, /must start with '\$'/)
    end

    it "raises clear error for missing path segments" do
      expect do
        described_class.extract(json, "$.user.name")
      end.to raise_error(RSpec::Rest::MissingJsonPathError, /did not match path segment/)
    end
  end
end
