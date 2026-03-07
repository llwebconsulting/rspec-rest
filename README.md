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

## Before and After (Rack::Test to rspec-rest)

The example below shows the same behavior test written two ways.

Before (`Rack::Test` + manual response parsing):

```ruby
RSpec.describe MyApp::V1::Posts, type: :request do
  include Rack::Test::Methods

  def app
    MyApp::Base
  end

  let(:auth_token) { "test-token" }
  let!(:posts) { create_list(:post, 3).sort_by(&:created_at).reverse }

  before { header "Authorization", "Bearer #{auth_token}" }

  it "returns posts page 1" do
    get "/api/v1/posts", { page: 1, per_page: 10 }
    payload = JSON.parse(last_response.body)

    expect(last_response.status).to eq(200)
    expect(payload.size).to eq(3)
    expect(payload.first["id"]).to eq(posts.first.id)
    expect(payload.first["author"]["id"]).to eq(posts.first.author.id)
  end
end
```

After (`rspec-rest` DSL):

```ruby
RSpec.describe "Posts API" do
  include RSpec::Rest

  let(:auth_token) { "test-token" }
  let!(:posts) { create_list(:post, 3).sort_by(&:created_at).reverse }

  api do
    app MyApp::Base
    base_path "/api/v1"
    default_format :json
  end

  resource "/posts" do
    get "/" do
      bearer auth_token
      query page: 1, per_page: 10

      expect_status 200
      expect_json array_of(hash_including("id" => integer, "author" => hash_including("id" => integer)))
      expect_json_at "$[0].id", posts.first.id
      expect_json_at "$[0].author.id", posts.first.author.id
      expect_page_size 10
      expect_max_page_size 20
    end
  end
end
```

What improves:

- Request setup is declarative (`api`, `resource`, `query`, `json`).
- JSON expectations are concise and structure-aware.
- Failures include request/response context plus a reproducible `curl`.

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

## Shared Request Presets

Define shared request defaults at group/resource scope:

- `with_headers(hash)`
- `with_query(hash)`
- `with_auth(token)` (sets `Authorization: Bearer <token>`)

Nested resources inherit presets, and request-level builders (`header`, `query`, `bearer`) can override them.

```ruby
with_query locale: "en"

resource "/posts" do
  with_auth "token-123"
  with_headers "X-Client" => "mobile"

  get "/" do
    query page: 2
    expect_status 200
  end
end
```

## Request Builders

Inside verb blocks:

- `header(key, value)`
- `headers(hash)`
- `bearer(token)`
- `unauthenticated!`
- `query(hash)`
- `json(hash_or_string)`
- `multipart!`
- `file(param_key, file_or_path, content_type: nil, filename: nil)`
- `path_params(hash)`

Example:

```ruby
post "/" do
  headers "X-Trace-Id" => "abc-123"
  bearer "token-123"
  query include_details: "true"
  json "email" => "dev@example.com", "name" => "Dev"
  expect_status 201
end
```

Multipart upload example:

```ruby
post "/uploads" do
  multipart!
  file :file, Rails.root.join("spec/fixtures/files/sample_upload.txt"), content_type: "text/plain"
  expect_status 201
  expect_json hash_including("filename" => "sample_upload.txt")
end
```

## Expectations

Available expectation helpers:

- `expect_status(code)`
- `expect_header(key, value_or_regex)`
- `expect_json(expected = nil, &block)`
- `expect_json_at(selector, expected = nil, &block)`
- `expect_error(status:, message: nil, includes: nil, field: nil, key: "error")`
- `expect_page_size(size, selector: "$")`
- `expect_max_page_size(max, selector: "$")`
- `expect_ids_in_order(ids, selector: "$[*].id")`

`expect_json` supports:

- matcher mode:
  - `expect_json hash_including("id" => integer)`
- equality mode:
  - `expect_json("id" => 1, "email" => "jane@example.com", "name" => "Jane")`
- block mode:
  - `expect_json { |payload| expect(payload["id"]).to integer }`

`expect_json_at` supports the same matcher/equality/block modes against a selected path:

- matcher mode:
  - `expect_json_at "$.user.id", integer`
- equality mode:
  - `expect_json_at "$.user.email", "jane@example.com"`
- block mode:
  - `expect_json_at "$.items[0]" { |item| expect(item["id"]).to integer }`

`expect_error` is a convenience helper for common API error payload assertions:

```ruby
get "/{id}" do
  path_params id: 999
  expect_error status: 404, message: "Post not found"
end
```

Pagination helpers:

```ruby
get "/" do
  query page: 2, per_page: 10
  expect_status 200
  expect_page_size 10
  expect_max_page_size 20
  expect_ids_in_order [30, 29, 28, 27, 26, 25, 24, 23, 22, 21]
end
```

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
