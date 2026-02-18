# rspec-rest

`rspec-rest` is a Ruby gem for writing concise, behavior-first REST API tests
with RSpec and Rack::Test.

The goal is to make API specs read like behavior specs instead of HTTP plumbing.

## Status

This project is in active development.

- Milestone 0 (gem bootstrap + harness) is complete.
- Milestones 1+ (core runtime, DSL, captures, failure formatting) are in progress.

## Why this gem

`rspec-rest` is designed for Ruby/Rails engineers who want:

- Less request-spec boilerplate
- Reusable API resource groupings
- Cleaner JSON assertions
- Better failure diagnostics with request/response context
- Reproducible `curl` output for failing requests (planned for v1)

## Planned v1 capabilities

- Rack::Test in-process request execution
- RSpec integration and DSL entrypoint (`include RSpec::Rest`)
- `api` and `resource` blocks
- Verb helpers: `get/post/put/patch/delete`
- Request builders: `header`, `headers`, `json`, `query`, `path_params`
- Expectations: `expect_status`, `expect_header`, `expect_json`
- Captures: `capture(:name, "$.path")`, `get(:name)`
- Failure output with request/response dump
- Auto-generated `curl` command on request assertion failures

## Installation

Once published:

```ruby
# Gemfile
gem "rspec-rest"
```

Then run:

```bash
bundle install
```

For local development before release:

```ruby
# Gemfile
gem "rspec-rest", git: "https://github.com/llwebconsulting/rspec-rest.git"
```

## Quick start (target DSL)

This is the intended v1 usage pattern:

```ruby
RSpec.describe "Users API" do
  include RSpec::Rest

  api do
    app Rails.application
    base_headers "Accept" => "application/json"
  end

  resource "/v1/users" do
    get "/" do
      expect_status 200
    end

    post "/" do
      json name: "Carl", email: "carl@example.com"
      expect_status 201
      capture :user_id, "$.id"
    end

    get "/{user_id}" do
      path_params user_id: get(:user_id)
      expect_status 200
    end
  end
end
```

## Current development harness

The repository currently includes a minimal Rack app and baseline specs to
support iterative gem development.

### Test app endpoints

- `GET /v1/users`
- `POST /v1/users`
- `GET /v1/users/:id`
- `GET /v1/bad_json`

Run tests locally:

```bash
bundle exec rspec
bundle exec rubocop
```

## Architecture (planned)

Core modules/classes:

- `RSpec::Rest::Config`
- `RSpec::Rest::Session`
- `RSpec::Rest::Response`
- `RSpec::Rest::DSL`
- `RSpec::Rest::JsonSelector`
- `RSpec::Rest::RequestRecorder` (for failure-time `curl`)

## Development

Setup:

```bash
bundle install
```

Common commands:

```bash
bundle exec rspec
bundle exec rubocop
```

CI runs both checks on pushes to `main` and on pull requests.

## Roadmap

Tracked as GitHub issues in milestone order:

1. Bootstrap gem and baseline harness
2. Core config/session/response runtime
3. DSL core (`api/resource/verbs/builders`)
4. Expectations and JSON type helpers
5. Captures and minimal JSON selector
6. Failure output formatter
7. Auto-generated `curl` reproduction
8. Docs and v1 acceptance pass

## Changelog

See `CHANGELOG.md` for release history and unreleased changes.

## Contributing

- Open an issue for bugs, proposals, and roadmap-aligned work.
- Use the PR template at `.github/pull_request_template.md`.
- Include tests for behavior changes.

## License

MIT. See `LICENSE`.
