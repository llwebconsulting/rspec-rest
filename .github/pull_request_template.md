# Pull Request

## Summary
Describe what changed and why.

## Related Issue
Closes #

## User Story
As a `<type of user>`, I want `<goal>`, so that `<outcome>`.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Notes
List key design decisions, tradeoffs, and any intentional deviations from plan.

## Testing
- [ ] `bundle exec rspec`
- [ ] Added/updated specs for changed behavior
- [ ] Manual verification steps (if applicable)

### Test Evidence
Paste relevant output or describe results.

## Checklist
- [ ] Backward compatibility considered
- [ ] Errors/failure messages are actionable
- [ ] README/docs updated (if behavior changed)
- [ ] CHANGELOG updated (if release-impacting)

## GitHub Copilot Review Instructions
When reviewing this PR, focus on the following:

1. Adhere to SOLID principles:
   - Single responsibility for classes/modules.
   - Open/closed design for extensibility.
   - Liskov substitution and interface consistency.
   - Interface segregation (small, focused APIs).
   - Dependency inversion where practical.
2. Follow Ruby gem best practices:
   - Clear public API boundaries and stable namespace (`RSpec::Rest`).
   - Minimal dependencies and explicit version constraints.
   - Meaningful error types/messages and defensive input handling.
   - Avoid global side effects/monkeypatching.
3. Follow RSpec-integrated gem best practices:
   - Deterministic specs (no order leakage, no shared mutable state).
   - Per-example isolation for config/session/captures.
   - Matchers and failures should produce high-signal diagnostics.
   - Keep DSL behavior explicit, predictable, and well-covered by specs.
4. Project-specific expectations:
   - Preserve Rack::Test in-process execution for speed.
   - Keep JSON handling robust (invalid JSON, missing keys/selectors).
   - Failure output must include enough request/response context to debug quickly.
   - Prefer readable, maintainable DSL implementation over clever metaprogramming.

If you find issues, provide concrete suggestions and point to exact files/lines.
