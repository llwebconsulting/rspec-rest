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

The first two examples below test the same behavior in two styles.

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
    with_auth auth_token

    get "/", "returns posts page 1" do
      query page: 1, per_page: 10

      expect_status 200
      expect_json array_of(hash_including("id" => integer, "author" => hash_including("id" => integer)))
      expect_json_first hash_including("id" => posts.first.id)
      expect_json_item(0) { |item| expect(item["author"]["id"]).to eq(posts.first.author.id) }
    end
  end
end
```

What improves in the apples-to-apples rewrite:

- Request setup is declarative (`api`, `resource`, `with_auth`, `query`).
- JSON assertions read closer to the business intent (`expect_json_first`, `expect_json_item`).
- Failure output includes request/response context and a reproducible `curl`.

Beyond the baseline rewrite, `rspec-rest` can also express additional API concerns
with concise helpers:

```ruby
RSpec.describe "Posts API" do
  include RSpec::Rest

  let(:auth_token) { "test-token" }

  api do
    app MyApp::Base
    base_path "/api/v1"
    default_format :json
  end

  contract :post_summary do
    hash_including("id" => integer, "author" => hash_including("id" => integer))
  end

  resource "/posts" do
    with_auth auth_token

    get "/" do
      query page: 1, per_page: 10
      expect_status 200
      expect_json array_of(expect_json_contract(:post_summary))
      expect_page_size 10
    end

    get "/{id}" do
      path_params id: 999_999
      expect_error status: 404, message: "Post not found"
    end
  end

  resource "/uploads" do
    with_auth auth_token

    post "/" do
      multipart!
      file :file, Rails.root.join("spec/fixtures/files/sample_upload.txt"), content_type: "text/plain"
      expect_status 201
      expect_json hash_including("filename" => "sample_upload.txt")
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
  - optional form: `get(path, description = nil) { ... }`

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

Example with an explicit behavior name:

```ruby
resource "/users" do
  get "/", "returns public users for authenticated client" do
    expect_status 200
  end
end
```

RSpec example output uses the composed full route (including `base_path`) and appends the optional description, for example:
- `GET /v1/users - returns public users for authenticated client`

Note: Example names (including `base_path`) are composed when the verb macro is evaluated. To ensure the example names include `base_path`, declare your `api` (and its `base_path`) before defining `resource` blocks and their verbs. If you configure `api`/`base_path` afterward, requests will use the configured `base_path`, but the previously defined example names will not reflect it.
## Shared Request Presets

Define shared request defaults at group/resource scope:

- `with_headers(hash)`
- `with_query(hash)`
- `with_auth(token)` (sets `Authorization: Bearer <token>`)

Use presets when your API requires repeated request context across many endpoints,
for example auth headers, locale/tenant query params, client/app version headers,
or other codebase-specific defaults.

Nested resources inherit presets, and request-level builders (`header`, `query`, `bearer`) can override them.

Typical pattern:
- set broad defaults at top-level (`with_query`, `with_headers`)
- narrow defaults at resource scope (`with_auth`, resource-specific headers)
- override per request only when behavior differs

```ruby
with_query locale: "en"
with_headers "X-Tenant-Id" => "tenant-123"

resource "/posts" do
  with_auth ENV.fetch("API_TOKEN", "token-123")
  with_headers "X-Client" => "mobile"

  get "/" do
    query page: 2
    expect_status 200
  end

  get "/admin" do
    header "X-Client", "internal-tool" # request-level override
    query locale: "fr"                 # request-level override
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
- `expect_json_contract(name)`
- `expect_json_at(selector, expected = nil, &block)`
- `expect_json_first(expected = nil, &block)`
- `expect_json_item(index, expected = nil, &block)`
- `expect_json_last(expected = nil, &block)`
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

For common array-item checks, use Ruby-style helpers instead of selector strings:

- `expect_json_first(...)`
- `expect_json_item(index, ...)`
- `expect_json_last(...)`

```ruby
expect_json_first hash_including("id" => integer)
expect_json_item 2, hash_including("name" => "Third")
expect_json_last { |item| expect(item["id"]).to integer }
```

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

## Lightweight Contracts

A contract is a named, reusable JSON expectation (usually a response shape matcher).
Define it once in your spec group, then apply it anywhere with `expect_json_contract`.

```ruby
contract :post_summary do
  hash_including(
    "id" => integer,
    "title" => string,
    "author" => hash_including("id" => integer)
  )
end

get "/" do
  expect_status 200
  expect_json array_of(expect_json_contract(:post_summary))
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

Example (truncated):

```text
expected: 201
     got: 422

Request:
POST /api/v1/posts
Headers:
  Accept: application/json
  Authorization: [REDACTED]
  Content-Type: application/json
Body:
{
  "title": "",
  "body": "Example"
}

Response:
Status: 422
Headers:
  Content-Type: application/json
Body:
{
  "error": "Validation failed",
  "details": {
    "title": ["can't be blank"]
  }
}

Reproduce with:
curl -X POST 'http://localhost:3000/api/v1/posts' -H 'Accept: application/json' -H "Authorization: Bearer $API_AUTH_TOKEN" -H 'Content-Type: application/json' -d '{"title":"","body":"Example"}'
```

Before running an authenticated command, set your token:

```bash
export API_AUTH_TOKEN="your_token_here"
```

Then paste the generated `curl` command directly in your terminal for fast manual debugging.

## Contributing

Contributions are welcome.

Recommended workflow:

1. Fork the repository on GitHub.
2. Clone your fork locally.
3. Create a feature branch from `main`.
4. Make your changes with tests/docs as needed.
5. Run quality checks locally:
   - `bundle exec rspec`
   - `bundle exec rubocop`
6. Commit and push your branch to your fork.
7. Open a Pull Request from your fork to this repository.

Pull request guidelines:

- Keep changes focused and include context in the PR description.
- Add or update specs for behavior changes.
- Update README/CHANGELOG when public behavior changes.
- Ensure CI is green before requesting final review.

Reporting issues and feature ideas:

- Use GitHub Issues and choose the appropriate template:
  - Bug report for incorrect behavior (include expected vs actual behavior and repro steps).
  - Feature request for enhancement ideas.
- Feature suggestions are appreciated and encouraged.
- The fastest path to getting a feature implemented is to open a pull request with the proposed change and tests.

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

See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT. See [LICENSE](./LICENSE).
