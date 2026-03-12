# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project aims to follow
Semantic Versioning.

## [Unreleased]

### Added
- `expect_json_at` now supports top-level shorthand selectors:
  - Symbol keys (for example `:message`)
  - plain String keys (for example `"message"`)
  Full JSONPath selectors (for example `"$.items[0].id"`) remain supported.
- `contract_with(:name, overrides)` for contract matcher composition with specific
  value assertions while preserving the base contract shape/type expectations.

## [0.4.0] - 2026-03-11

### Added
- Verb DSL now supports keyword request paths:
  - `get path: "/users", description: "..." do ... end`
  - same keyword `path:` support for `post`, `put`, `patch`, and `delete`.

### Deprecated
- Positional verb path arguments are deprecated and scheduled for removal in `1.0`:
  - `get "/users", description: "..." do ... end`
  Use keyword paths instead:
  - `get path: "/users", description: "..." do ... end`

## [0.3.0] - 2026-03-10

### Added
- Contract lookup helper for matcher composition in examples:
  - `contract(:name)`
- Internal deprecation utility for gem APIs:
  - `RSpec::Rest::Deprecation.warn(key:, message:)`
  - once-per-key warning emission in RSpec output.
- Keyword request description support on verb DSL calls:
  - `get(path, description: "...") { ... }` (and same for other verbs).

### Changed
- Failure-time `curl` output now uses an auth token environment placeholder for redacted auth-like headers, improving copy/paste usability:
  - `Authorization: Bearer $API_AUTH_TOKEN`
- Redacted auth scheme prefixes are preserved in `curl` output for `Authorization` and `Proxy-Authorization` (for example `Basic`, `Digest`).
- README examples now prefer:
  - `contract(:name)` over nested `expect_json_contract(...)`
  - keyword request descriptions (`description:`).
- Added README RuboCop compatibility guidance for:
  - `Rails/HttpPositionalArguments`
  - `RSpec/EmptyExampleGroup`.

### Deprecated
- `expect_json_contract(name)` is deprecated and scheduled for removal in `1.0`.
  Use `contract(:name)` for contract lookup in examples.
- Positional verb descriptions are deprecated and scheduled for removal in `1.0`:
  - `get(path, "description") { ... }`
  Use keyword descriptions instead:
  - `get(path, description: "...") { ... }`

## [0.2.0] - 2026-03-08

### Added
- JSON array item expectation helpers:
  - `expect_json_first(expected = nil, &block)`
  - `expect_json_item(index, expected = nil, &block)`
  - `expect_json_last(expected = nil, &block)`
- Optional behavior descriptions on verb DSL calls:
  - `get(path, description = nil) { ... }` (and same for other verbs)
- Full-route example naming support in DSL output (composed from `base_path` + resource path + endpoint path).
- Shared path composition utility used by both request execution and example naming.

### Changed
- README examples and expectation helper docs updated for:
  - Ruby-style JSON item helpers
  - Optional verb descriptions and full-route example names

### Fixed
- `expect_json_item` now validates index type and reports non-integer indexes via actionable expectation failures.
- JSON value assertion semantics are centralized across `expect_json`, `expect_json_at`, and JSON item helpers to reduce drift.
- Unknown/invalid JSON item and contract expectation failures continue to include enriched request/response/curl diagnostics.

## [0.1.0] - 2026-03-07

### Added
- Initial public release of `rspec-rest`.
- Core runtime:
  - `Config`, `Session`, and `Response` objects
  - JSON parsing with `InvalidJsonError`
- DSL:
  - `api`, `resource`, `get/post/put/patch/delete`
  - request builders: `header`, `headers`, `query`, `json`, `path_params`
  - auth builders: `bearer`, `unauthenticated!`
  - multipart builders: `multipart!`, `file(...)`
  - shared presets: `with_headers`, `with_query`, `with_auth`
- Expectations:
  - `expect_status`, `expect_header`, `expect_json`, `expect_json_at`
  - error/pagination helpers: `expect_error`, `expect_page_size`, `expect_max_page_size`, `expect_ids_in_order`
  - reusable contract helpers: `contract`, `expect_json_contract`
  - helper matchers: `integer`, `string`, `boolean`, `array_of`, `hash_including`
- Captures and selectors:
  - `capture` / `get`
  - minimal selector support (`$.a.b`, `$.items[0].id`)
- Failure diagnostics:
  - request/response dump formatter
  - pretty-printed JSON output
  - configurable sensitive-header redaction
- `curl` reproduction:
  - generated `curl` command in failure output
  - full URL generation with `base_url`
  - header/body/query reproduction with redaction
- Tooling/docs:
  - RSpec + RuboCop + GitHub Actions CI
  - PR and issue templates
  - expanded README docs
  - acceptance and formatter specs
