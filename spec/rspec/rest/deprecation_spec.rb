# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::Rest::Deprecation do
  before { described_class.reset! }
  after { described_class.reset! }

  it "emits warnings through the RSpec reporter when available" do
    reporter = instance_double(RSpec::Core::Reporter, message: nil)
    allow(described_class).to receive(:rspec_reporter).and_return(reporter)

    described_class.warn(key: :old_api, message: "old_api is deprecated")

    expect(reporter).to have_received(:message).with("DEPRECATION: old_api is deprecated")
  end

  it "falls back to Kernel.warn when reporter is unavailable" do
    allow(described_class).to receive(:rspec_reporter).and_return(nil)
    allow(Kernel).to receive(:warn)

    described_class.warn(key: :old_api, message: "old_api is deprecated")

    expect(Kernel).to have_received(:warn).with("DEPRECATION: old_api is deprecated")
  end

  it "emits only once per deprecation key" do
    reporter = instance_double(RSpec::Core::Reporter, message: nil)
    allow(described_class).to receive(:rspec_reporter).and_return(reporter)

    described_class.warn(key: :old_api, message: "old_api is deprecated")
    described_class.warn(key: :old_api, message: "old_api is deprecated")

    expect(reporter).to have_received(:message).once
  end
end
