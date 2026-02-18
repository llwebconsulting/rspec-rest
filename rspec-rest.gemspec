# frozen_string_literal: true

require_relative "lib/rspec/rest/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-rest"
  spec.version = RSpec::Rest::VERSION
  spec.authors = ["Carl"]
  spec.email = ["carl@example.com"]

  spec.summary = "Rack::Test + RSpec DSL for REST API testing"
  spec.description = "A Ruby gem for concise, behavior-first REST API specs backed by Rack::Test and RSpec."
  spec.homepage = "https://github.com/llwebconsulting/rspec-rest"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/llwebconsulting/rspec-rest"
  spec.metadata["changelog_uri"] = "https://github.com/llwebconsulting/rspec-rest/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == gemspec) ||
        f.start_with?("bin/", "test/", "spec/", ".github/") ||
        f.end_with?(".gem")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rack-test", "~> 2.1"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", ">= 1.72", "< 2.0"
  spec.add_development_dependency "rubocop-rspec", "~> 3.4"
end
