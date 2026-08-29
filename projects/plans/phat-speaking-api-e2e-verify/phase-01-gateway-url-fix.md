# Phase 1: `pte-app` Gateway URL Fix

## Requirements
`pte-app`'s API client points at the real gateway (`http://localhost:8080`) instead of the raw `iam` service port (`8081`), so every subsequent gateway-routed call (`/api/{service}/**`) actually reaches its target service instead of hitting a bare `iam` instance that doesn't understand the prefix.

## Steps
1. Update the hardcoded `gatewayBaseUrl` constant to the correct gateway port.
2. Search the rest of the `pte-app` codebase for any other hardcoded references to the wrong port, to confirm this is the only place it needs to change.
3. Rebuild or hot-restart the app to confirm the edit introduces no compile errors.

## Success Criteria
- `AppConfig.gatewayBaseUrl` equals `http://localhost:8080`.
- No other hardcoded reference to port `8081` remains anywhere in `pte-app`'s source.
- The app builds/hot-restarts cleanly after the change.

## Risks
- Other call sites or test fixtures also hardcode the old port and get missed — Mitigation: repo-wide search for the literal wrong port before considering this phase done, not just the one known file.

## Testing
No meaningful automated test applies — this is a single hardcoded string constant with no branching logic to unit-test. Correctness is confirmed indirectly in Phase 3, when a real login call through this URL either succeeds or fails.
