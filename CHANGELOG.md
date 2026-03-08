# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project aims to follow
Semantic Versioning.

## [Unreleased]

No changes yet.

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
