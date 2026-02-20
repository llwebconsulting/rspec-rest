# rspec-rest

`rspec-rest` is a Ruby gem for behavior-first REST API specs built on top of
RSpec and Rack::Test.

It focuses on:

- concise request DSL
- JSON-first expectations
- capture/reuse of response values
- high-signal failure output with request/response context
- auto-generated `curl` reproduction commands on failures

## Status

The gem is pre-release and in active development toward `0.1.0`.

## Installation

When published:

```ruby
# Gemfile
gem "rspec-rest"
```

Until then, use GitHub:

```ruby
# Gemfile
gem "rspec-rest", git: "https://github.com/llwebconsulting/rspec-rest.git"
```

Then:

```bash
bundle install
```

## Quick Start

```ruby
RSpec.describe "Users API" do
  include RSpec::Rest

  api do
    app Rails.application
    base_path "/v1"
    base_headers "Accept" => "application/json"
    default_format :json
    base_url "http://localhost:3000" # used for failure-time curl reproduction
  end

  resource "/users" do
    get "/" do
      expect_status 200
      expect_header "Content-Type", "application/json"
      expect_json array_of(hash_including("id" => integer, "email" => string))
    end

    post "/" do
      json "email" => "carl@example.com", "name" => "Carl"
      expect_status 201
      capture :user_id, "$.id"
    end
  end
end
```

## API Config (`api`)

`api` defines shared runtime configuration for a spec group.

```ruby
api do
  app Rails.application
  base_path "/v1"
  base_headers "Accept" => "application/json"
  default_format :json
  base_url "http://localhost:3000"
  redact_headers ["Authorization", "Cookie", "Set-Cookie"]
end
```

Supported config:

- `app`: Rack app (required)
- `base_path`: base request path prefix
- `base_headers`: default headers merged into every request
- `default_format`: set to `:json` to default `Accept: application/json`
- `base_url`: used for generated curl commands (`http://example.org` default)
- `redact_headers`: headers redacted in failure output and curl

## Resources And Verbs

- `resource "/users" do ... end`
- `get`, `post`, `put`, `patch`, `delete`

Resource paths are composable and support placeholders:

```ruby
resource "/users" do
  resource "/{id}/posts" do
    get "/" do
      path_params id: 1
      expect_status 404
    end
  end
end
```

## Request Builders

Inside verb blocks:

- `header(key, value)`
- `headers(hash)`
- `query(hash)`
- `json(hash_or_string)`
- `path_params(hash)`

Example:

```ruby
post "/" do
  headers "X-Trace-Id" => "abc-123"
  query include_details: "true"
  json "email" => "dev@example.com", "name" => "Dev"
  expect_status 201
end
```

## Expectations

Available expectation helpers:

- `expect_status(code)`
- `expect_header(key, value_or_regex)`
- `expect_json(expected = nil, &block)`

`expect_json` supports:

- matcher mode:
  - `expect_json hash_including("id" => integer)`
- equality mode:
  - `expect_json("id" => 1, "email" => "jane@example.com", "name" => "Jane")`
- block mode:
  - `expect_json { |payload| expect(payload["id"]).to integer }`

JSON type helpers:

- `integer`
- `string`
- `boolean`
- `array_of(matcher)`
- `hash_including(...)`

## Captures

Capture response values and reuse them later in the same example:

- `capture(:name, selector)`
- `get(:name)`

Selector syntax (minimal JSON selector):

- `$.a.b`
- `$.items[0].id`

Example:

```ruby
post "/" do
  json "email" => "flow@example.com", "name" => "Flow"
  expect_status 201
  capture :user_id, "$.id"
end
```

## Failure Output and curl Reproduction

When an expectation fails, output includes:

- request method/path
- request headers/body
- response status/headers/body
- generated `curl` command

Sensitive headers are redacted by default and can be customized via
`redact_headers`.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Namespace

Gem name: `rspec-rest`  
Ruby namespace: `RSpec::Rest`

## Changelog

See `CHANGELOG.md`.

## License

MIT. See `LICENSE`.
