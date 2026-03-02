# Changelog

## 2026-03-02

### Added
- Rails engine integration for webhook handling (`Yookassa::Engine`).
- Default webhook controller (`Yookassa::WebhooksController`) with built-in authenticity checks.
- Config options for webhook security:
  - `webhook_token` (secret URL token in path)
  - `webhook_allowed_ips` (YooKassa source allowlist, overridable)
- RSpec coverage for webhook controller behavior.
- Cuprite browser spec for real browser webhook request flow.
- CI job for browser tests in GitHub Actions.

### Changed
- Documentation updated to use gem-based webhook integration instead of app-side hand-rolled service/controller code.
- Webhook security guidance switched to YooKassa-documented approach:
  - secret URL token
  - source IP allowlist
  - API re-fetch and object/status comparison

### Notes
- No webhook signature header validation is implemented because YooKassa webhook docs describe authenticity checks via source IP and object status verification.
- Source for default IP ranges: https://yookassa.ru/developers/using-api/webhooks#ip
