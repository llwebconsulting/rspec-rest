# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project aims to follow
Semantic Versioning.

## [Unreleased]

### Added
- Core runtime:
  - `Config`, `Session`, and `Response` objects
  - JSON parsing with `InvalidJsonError`
- DSL:
  - `api`, `resource`, `get/post/put/patch/delete`
  - request builders: `header`, `headers`, `query`, `json`, `path_params`
- Expectations:
  - `expect_status`, `expect_header`, `expect_json`
  - helper matchers: `integer`, `string`, `boolean`, `array_of`, `hash_including`
- Captures and selectors:
  - `capture` / `get`
  - minimal selector support (`$.a.b`, `$.items[0].id`)
- Failure diagnostics:
  - request/response dump formatter
  - pretty-printed JSON output
  - configurable sensitive-header redaction
- cURL reproduction:
  - generated `curl` command in failure output
  - full URL generation with `base_url`
  - header/body/query reproduction with redaction
- Tooling/docs:
  - RSpec + RuboCop + GitHub Actions CI
  - PR template
  - expanded README docs
  - acceptance and formatter specs

## [0.1.0] - TBD

### Added
- Initial public release of `rspec-rest` (planned)
