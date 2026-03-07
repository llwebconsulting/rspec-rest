# rspec-rest — Plan 0.2

## 1) Goal
Ship `0.2.0` as a developer-experience release focused on reducing repetitive request-spec boilerplate in real-world API suites (especially Rails + Grape style APIs).

Primary outcomes:
- less auth/header/query setup repetition
- cleaner nested JSON assertions
- first-class API error assertions
- better support for multipart/file upload flows
- reusable request presets at resource scope
- simpler pagination assertions
- optional lightweight response contracts

---

## 2) Scope

### In scope for `0.2.0`
- Auth helpers
- JSON path assertions
- Error payload helpers
- Multipart/file upload builder
- Request presets/shared modifiers
- Pagination helpers
- Lightweight response contract helper

### Out of scope for `0.2.0`
- OpenAPI schema generation/validation
- Full JSONPath implementation
- Response snapshot framework
- Alternate non-Rack test runner

---

## 3) Proposed DSL Additions

### 3.1 Auth helpers
- `bearer(token)`
- `unauthenticated!` (removes `Authorization` from current request headers)

Example:
```ruby
get "/" do
  bearer access_token
  expect_status 200
end
```

### 3.2 JSON path assertions
- `expect_json_at(selector, expected = nil, &block)`
  - selector supports existing minimal syntax (`$.a.b`, `$.items[0].id`)
  - matcher/value/block behavior mirrors `expect_json`

Example:
```ruby
expect_json_at "$.comments[0].author.id", eq(user.id)
```

### 3.3 Error payload helpers
- `expect_error(status:, message: nil, includes: nil, field: nil, key: "error")`
  - asserts status first
  - checks error key content (string or array)
  - `includes:` supports partial matching
  - `field:` adds convenience for validation-style errors

Examples:
```ruby
expect_error status: 422, message: "Unable to like post"
expect_error status: 400, includes: "font_size"
```

### 3.4 Multipart/file upload
- `multipart!`
- `file(param_key, file_or_path, content_type: nil, filename: nil)`

Example:
```ruby
post "/" do
  multipart!
  file :image, Rails.root.join("spec/fixtures/files/test_image.jpg"), content_type: "image/jpeg"
  expect_status 201
end
```

### 3.5 Request presets/shared modifiers
- `with_headers(hash)`
- `with_query(hash)`
- `with_auth(token)` (resource/group-level default bearer)
- presets are inherited by nested `resource` blocks and merged with per-request values

Example:
```ruby
resource "/posts" do
  with_auth token
  with_query per_page: 20

  get "/" do
    query page: 2
    expect_status 200
  end
end
```

### 3.6 Pagination helpers
- `expect_page_size(size)`
- `expect_max_page_size(max)`
- `expect_ids_in_order(ids, selector: "$[*].id")`

Examples:
```ruby
expect_page_size 10
expect_max_page_size 20
expect_ids_in_order [post3.id, post2.id, post1.id]
```

### 3.7 Lightweight response contracts
- `contract(name, &definition)` to define reusable JSON matcher blocks
- `expect_json_contract(name)`

Example:
```ruby
contract :post_summary do
  hash_including(
    "id" => integer,
    "title" => string,
    "author" => hash_including("id" => integer)
  )
end

expect_json array_of(expect_json_contract(:post_summary))
```

---

## 4) Milestones

### Milestone 1: Auth + JSON path assertions
Deliver:
- `bearer`, `unauthenticated!`
- `expect_json_at`

Acceptance:
- Can replace manual `Authorization` header setup in specs
- Nested assertion example passes/fails with clear failure output + curl

### Milestone 2: Error helpers + pagination helpers
Deliver:
- `expect_error`
- `expect_page_size`, `expect_max_page_size`, `expect_ids_in_order`

Acceptance:
- Validation/permission error examples become one-liners
- Pagination assertions no longer rely on repeated `json.size`/manual id extraction

### Milestone 3: Multipart/file upload
Deliver:
- `multipart!`
- `file(...)`

Acceptance:
- Image/video upload request specs can be expressed without raw Rack::Test multipart plumbing
- Failing multipart expectations still include full request dump/curl

### Milestone 4: Request presets/shared modifiers
Deliver:
- `with_headers`, `with_query`, `with_auth`
- merge/inheritance behavior for nested resources

Acceptance:
- Shared auth + common pagination defaults are declared once and reused
- Request-local values override defaults predictably

### Milestone 5: Lightweight contracts
Deliver:
- `contract`
- `expect_json_contract`

Acceptance:
- Repeated response-shape checks can be defined once and reused
- Contract failures identify contract name and failing matcher path

---

## 5) Technical Notes

- Keep features additive and backward compatible with `0.1.x` DSL.
- Reuse existing `JsonSelector` for `expect_json_at` to avoid duplicating selector logic.
- Ensure new helpers all route through current failure wrapper so request dump/curl remains consistent.
- Avoid introducing global RSpec monkeypatching.
- Prefer explicit config and per-example isolation semantics already used by the gem.

---

## 6) Testing Strategy

Add/extend specs under:
- `spec/rspec/rest/dsl_spec.rb`
- `spec/rspec/rest/expectations_spec.rb` (new file if needed)
- `spec/rspec/rest/acceptance_spec.rb`
- `spec/rspec/rest/failure_output_spec.rb`

Minimum test matrix:
- happy path + failure path for each new helper
- interaction tests for presets merge/override behavior
- multipart request and content-type correctness
- error helper on both string and array payload formats
- pagination helper with array payload and invalid payload types

---

## 7) Documentation Deliverables

- Update README with:
  - new helper sections
  - one end-to-end "before vs after" covering auth + presets + JSON path assertions + pagination + errors + multipart uploads
  - multipart example
  - contract example
- Add a final doc-review checkpoint before `0.2.0` release:
  - verify README "before vs after" reflects the full implemented `0.2.0` feature set
  - if any milestone feature is intentionally excluded from the main "after" snippet, include a nearby focused snippet and call it out explicitly
- Add changelog entry for `0.2.0`.

---

## 8) Release Criteria (`0.2.0`)

- All new helpers implemented and documented
- Full spec suite green
- No regressions in existing DSL behavior
- Changelog updated
- Version bumped to `0.2.0`
