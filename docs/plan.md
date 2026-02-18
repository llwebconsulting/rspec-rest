# rspec-rest — Plan (Rack::Test + RSpec DSL for REST API testing)

## 1) Goal
Create a Ruby gem that provides a clean DSL for testing REST APIs using:
- **Rack::Test** for fast, in-process request execution (Rails-friendly)
- **RSpec** for expectations, matchers, and reporting

Primary objective: make API tests read like *behavior specs*, not HTTP plumbing.

---

## 2) Target User + Use Cases
### Target user
Ruby/Rails engineers writing request specs who want:
- Less boilerplate (headers/auth/base path)
- Cleaner JSON expectations
- Better failure output (request + response context)
- Reusable “API resources” blocks

### Core use cases
- Define an API client configuration once (base headers, auth)
- Group endpoints under resources (`/v1/users`)
- Perform requests with `get/post/put/patch/delete`
- Assert on status/headers/json quickly
- Capture values (token, ids) and reuse in later requests

---

## 3) Scope (v1)
### Must-have (v1)
- Rack::Test runner (in-process)
- RSpec integration
- DSL:
  - `api` block configuration
  - `resource` blocks
  - HTTP verb blocks
  - request builders: `json`, `query`, `header(s)`
  - expectations: `expect_status`, `expect_header`, `expect_json`
  - capture helpers: `capture` from JSONPath-like selectors (minimal)
- Helpful failure output:
  - method/path
  - request headers/body
  - response status/headers/body
  - JSON mismatch summary when possible

### Nice-to-have (v1.1 / v2)
- Schema-lite type matchers (integer/string/boolean/array/hash)
- Snapshot testing for JSON (golden files) with redactions
- Auth helpers (`auth :bearer`, `auth :cookie`)
- Support for Rails `ActionDispatch::IntegrationTest` session as an alternate runner
- Optional out-of-process HTTP runner

### Non-goals (v1)
- Full OpenAPI generation/validation
- Async/eventual consistency helpers
- Browser/UI testing
- Complex JSONPath implementation (keep minimal)

---

## 4) Proposed DSL (Public API)

### 4.1 Basic example
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
      expect_json do
        array_of hash_including("id" => integer, "email" => string)
      end
    end

    post "/" do
      json name: "Carl", email: "carl@example.com"
      expect_status 201
      capture :user_id, "$.id"
    end

    get "/{user_id}" do
      path_params user_id: get(:user_id)
      expect_status 200
      expect_json include("id" => get(:user_id))
    end
  end
end

4.2 DSL primitives

Top-level
	•	api { ... }
	•	app <rack_app> (required for Rack::Test)
	•	base_path "/v1" (optional)
	•	base_headers Hash
	•	default_format :json (optional)
	•	let_context store for captured values

Grouping
	•	resource "/v1/users" { ... }

Requests
	•	get(path) { ... }, post(path), put, patch, delete
	•	Request builder methods inside verb block:
	•	header(key, value)
	•	headers(hash)
	•	json(hash_or_string)
	•	query(hash) (converted to query string)
	•	path_params(hash) (simple templating: "/{id}")
	•	basic_auth(user, pass) (optional v1.1)
	•	bearer(token) (optional v1.1)

Expectations
	•	expect_status(code)
	•	expect_header(key, value_or_regex)
	•	expect_json(expected=nil, &block)
	•	if expected is provided: compare actual parsed JSON to matcher/value
	•	if block is provided: yield parsed JSON and allow expectations/matchers

Captures
	•	capture(:name, selector) where selector is minimal:
	•	$.foo.bar
	•	$.items[0].id
	•	get(:name) fetch captured values
	•	Captures should fail with a helpful message if missing

⸻

5) Architecture

5.1 Core objects
	•	RSpec::Rest::Config
	•	app, base_path, base_headers, default_format
	•	RSpec::Rest::Session
	•	wraps Rack::Test methods and tracks:
	•	current request headers/body/query
	•	last response
	•	capture store
	•	RSpec::Rest::DSL
	•	defines api, resource, and verb methods
	•	instantiates/uses a Session per example (or per group)
	•	RSpec::Rest::Response
	•	helper to access:
	•	status, headers, body
	•	json (parsed lazily, raises clear error if invalid JSON)
	•	RSpec::Rest::JsonSelector
	•	minimal selector parser for $.a.b[0].c

5.2 RSpec integration
	•	Provide a module RSpec::Rest to include in specs
	•	Add RSpec.configure helper for auto-including based on metadata:
	•	config.include RSpec::Rest, type: :rest (optional)
	•	Provide custom failure formatting by raising exceptions that include context
	•	exception message includes request/response dump

⸻

6) File/Module Layout (suggested)

rspec-rest/
  lib/
    rspec/rest.rb
    rspec/rest/version.rb
    rspec/rest/config.rb
    rspec/rest/session.rb
    rspec/rest/dsl.rb
    rspec/rest/response.rb
    rspec/rest/json_selector.rb
    rspec/rest/errors.rb
    rspec/rest/formatters/request_dump.rb
    rspec/rest/matchers/json_types.rb        # v1.1 (optional)
  spec/
    spec_helper.rb
    support/
      rack_app.rb                            # tiny Rack app for gem specs
    rspec/rest/
      dsl_spec.rb
      session_spec.rb
      json_selector_spec.rb
      failure_output_spec.rb
  README.md
  CHANGELOG.md
  Gemfile
  rspec-rest.gemspec


⸻

7) Implementation Plan (Agent-friendly Tasks)

Milestone 0 — Bootstrap gem
	•	bundle gem rspec-rest
	•	Add runtime deps:
	•	rack-test
	•	rspec (as development dependency; optionally runtime if needed)
	•	Set up RSpec in spec/spec_helper.rb
	•	Add a tiny Rack app in spec/support/rack_app.rb with a few endpoints:
	•	GET /v1/users => JSON array
	•	POST /v1/users => creates and returns id
	•	GET /v1/users/:id => JSON object
	•	GET /v1/bad_json => non-JSON body for error case

Acceptance:
	•	bundle exec rspec runs with a placeholder spec.

Milestone 1 — Core Config + Session + Response
	•	Config with app, base_path, base_headers, default_format
	•	Session:
	•	includes Rack::Test::Methods or wraps an internal Rack::Test session
	•	applies base headers + per-request headers
	•	builds path using base_path + resource + endpoint path
	•	supports sending JSON body with correct Content-Type
	•	exposes last_response via a Response wrapper
	•	Response#json parses JSON and raises InvalidJsonError with body snippet

Acceptance:
	•	Can perform a GET and parse JSON in a spec with no DSL yet.

Milestone 2 — DSL: api/resource/verbs + builders
	•	DSL module:
	•	api { ... } sets config for the example group
	•	resource(path) { ... } sets a scoped base for nested verbs
	•	get/post/put/patch/delete(path) { ... } executes request at example runtime
	•	Request builder methods inside verb blocks:
	•	header, headers, query, json, path_params
	•	Path templating for "/{id}" replacement

Acceptance:
	•	Example spec reads:
	•	resource "/v1/users" { get "/" { expect_status 200 } }
	•	Requests actually hit the Rack app.

Milestone 3 — Expectations
	•	expect_status(code)
	•	expect_header(key, expected)
	•	expect_json(expected=nil, &block)
	•	if expected responds to matches? treat as matcher
	•	else compare with ==
	•	if block given: yield parsed JSON
	•	Provide simple JSON type helpers (v1):
	•	integer, string, boolean, array_of, hash_including
	•	These can be thin wrappers around RSpec matchers or custom matchers

Acceptance:
	•	Can assert on:
	•	status
	•	header presence
	•	JSON structure/types

Milestone 4 — Captures (minimal selector)
	•	capture(name, selector) stores extracted value from parsed JSON
	•	get(name) retrieves stored value
	•	JsonSelector.extract(json, selector) supports:
	•	$.a.b
	•	$.items[0].id
	•	Failure messages:
	•	selector invalid
	•	path missing

Acceptance:
	•	POST /users captures id, later used in GET /users/{id}.

Milestone 5 — Failure output polish
	•	RequestDump helper that formats:
	•	METHOD PATH
	•	request headers
	•	request body (pretty JSON if possible)
	•	response status
	•	response headers
	•	response body (pretty JSON if possible)
	•	Ensure all DSL assertion failures include the dump

Acceptance:
	•	A failing spec shows enough info to debug without adding puts.

⸻

8) Decisions / Defaults
	•	Default Content-Type to application/json when json(...) is used
	•	Default Accept header to application/json if default_format :json set
	•	Session lifetime: per-example (safe isolation)
	•	Store captures per-example (not shared across examples unless explicitly)

⸻

9) README Outline (v1)
	•	What is rspec-rest?
	•	Installation
	•	Quick start
	•	Config (api block)
	•	Resources + verbs
	•	Request builders
	•	Expectations
	•	Captures
	•	Troubleshooting / failure output example

⸻

10) Acceptance Criteria (v1)
	•	A Rails app can include the gem and write specs with the DSL
	•	Specs run fast using Rack::Test in-process
	•	JSON assertions are concise
	•	Failure output includes full request/response context
	•	Captures enable multi-step API flows

⸻

11) Potential Naming / Namespace Notes

Gem name: rspec-rest
Ruby namespace: RSpec::Rest

(If RSpec::Rest conflicts in the ecosystem, fall back to RspecRest or RSpecRest.)

⸻

You didn’t miss it — I mentioned it earlier as a differentiator, but it didn’t make it into the formal plan. That’s on me.

And honestly? The auto-generated cURL on failure is one of the most compelling features you could ship in v1. It’s the kind of thing that makes engineers immediately say, “Oh, that’s nice.”

Let’s fix the plan properly.

Below is a drop-in addition you can paste into your markdown file.

⸻


## 12) Feature: Auto-Generated cURL on Failure (v1)

### Goal
Whenever a request expectation fails, rspec-rest should display a fully
reproducible `curl` command representing the request that just ran.

This allows developers to:
- Re-run the failing request outside of RSpec
- Share a failing request easily
- Debug against staging/production
- Copy/paste into Postman or terminal instantly

This is a first-class feature and should be included in v1.

---

## 12.1 Behavior

When a spec fails, the failure output should include:

- METHOD + URL
- Request headers
- Request body (if present)
- Response status
- Response body (truncated if large)
- Generated curl command

Example failure output:

Expected status 200 but got 422

Request:
POST /v1/users
Headers:
Accept: application/json
Content-Type: application/json
Body:
{“email”:“bad”}

Response:
Status: 422
Body:
{“error”:“email is invalid”}

Reproduce with:

curl -X POST http://localhost:3000/v1/users 
-H “Accept: application/json” 
-H “Content-Type: application/json” 
-d ‘{“email”:“bad”}’

---

## 12.2 Implementation Plan

### Add RequestRecorder

Create a new object:

- `RSpec::Rest::RequestRecorder`

Responsibilities:
- Store:
  - method
  - full URL
  - headers
  - body
- Generate curl string

Interface:

```ruby
recorder = RequestRecorder.new(
  method: :post,
  url: "http://example.com/v1/users",
  headers: { "Accept" => "application/json" },
  body: '{"email":"bad"}'
)

recorder.to_curl
```

⸻

12.3 Curl Generation Rules

Basic structure

curl -X METHOD URL

Headers

For each header:

-H "Key: Value"

Body

If body exists:

-d '<json>'

Rules:
	•	Escape single quotes in JSON body
	•	Preserve formatting (do NOT pretty-print)
	•	If body > 5KB, optionally truncate in display (not in curl)
	•	If binary body, skip -d and show comment

⸻

12.4 Config Options (Optional v1.1)

Allow:

api do
  base_url "http://localhost:3000"
  include_curl_on_failure true
  redact_headers ["Authorization"]
end

Redaction rules:
	•	Replace redacted header values with REDACTED
	•	Redact tokens inside Authorization header automatically by default

⸻

12.5 Integration Point

When any assertion fails:
	1.	Catch failure
	2.	Append:
	•	request dump
	•	response dump
	•	recorder.to_curl
	3.	Re-raise with enriched message

Prefer implementing via:
	•	Custom exception class
	•	Or wrapping expectation failures inside DSL methods

Do NOT monkeypatch RSpec globally.

⸻

12.6 Acceptance Criteria
	•	Failing request prints reproducible curl command
	•	Authorization headers are redacted
	•	Multi-line curl formatting is readable
	•	Works for:
	•	GET
	•	POST with JSON
	•	Query params
	•	Custom headers

---

This feature is high leverage for you specifically:

- You do a lot of API work (Grape, Rails, vendor integrations)
- You debug staging/prod issues
- You think in terms of infrastructure and reproducibility
- You care about developer ergonomics

This is exactly the kind of thing that makes a gem feel “serious.”

If you’d like, next we can:
- Refine the curl generator so it also supports query params cleanly
- Or design the failure formatting architecture so it's clean and not hacky

**Confidence: 0.92** (this is a strong v1 feature and very achievable technically).


**Confidence: 0.84** (this is a solid v1 plan; exact DSL details may shift slightly once you start using it in a real Rails app spec suite).