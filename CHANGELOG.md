# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project aims to follow
Semantic Versioning.

## [Unreleased]

No changes yet.

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
