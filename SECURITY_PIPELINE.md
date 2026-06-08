# Security Pipeline

This pipeline tracks the move from a demo mobile AI integration to a safer production architecture.

## Phase 1: Backend Proxy Hardening - Implemented

- Move OpenRouter API access out of Flutter and into `backend/server.js`.
- Read `OPENROUTER_API_KEY` from backend environment only.
- Add `BACKEND_CLIENT_TOKEN` support:
  - Flutter sends it as `X-Client-Token` when `--dart-define=BACKEND_CLIENT_TOKEN=...` is provided.
  - Backend rejects `/api/*` requests when `BACKEND_CLIENT_TOKEN` is configured and the header is missing or wrong.
- Add in-memory rate limiting for `/api/*` routes.
- Add configurable JSON/body and image-size limits.
- Validate supported intents, selected frame count, all frame count, frame metadata, and selected image presence.
- Add production HTTPS enforcement switch with `ENFORCE_HTTPS=true`.
- Disable `X-Powered-By` and add conservative response headers.
- Disable browser CORS by default; allow explicit `CORS_ALLOWED_ORIGINS` if needed.
- Prevent production Flutter builds from using direct AI providers unless explicitly allowed.
- Reject insecure non-local backend URLs in production Flutter builds.

## Phase 2: Production Deployment

- Deploy the backend behind HTTPS using a managed platform or reverse proxy.
- Set production environment variables in the host platform, not in committed files.
- Set `ENFORCE_HTTPS=true`.
- Set `TRUST_PROXY=true` only when the backend is behind a trusted proxy/load balancer.
- Configure domain allowlists and network firewall rules where available.
- Add health checks and uptime monitoring for `/health`.

## Phase 3: Stronger Authentication

`BACKEND_CLIENT_TOKEN` is a first production gate, but a static mobile token can still be extracted from an APK/IPA. Upgrade to one of these before public release:

- User login with short-lived backend-issued tokens.
- Device attestation such as Play Integrity API / App Attest.
- Per-user quotas and revocation.
- Server-side session auditing.

## Phase 4: Abuse and Cost Controls

- Replace in-memory rate limiting with Redis or a managed rate limit service for multi-instance deployments.
- Add per-user, per-device, and per-IP quotas.
- Add daily spend caps for OpenRouter calls.
- Add alerting for spikes, repeated validation failures, and high-cost usage.
- Add request IDs to backend logs, but never log API keys or base64 images.

## Phase 5: Privacy and Data Governance

- Publish a privacy policy explaining camera frame processing and third-party AI processing.
- Add explicit user consent for sending selected frames to the backend and AI provider.
- Avoid storing image frames unless a user explicitly opts in.
- Define retention rules for logs and metadata.
- Review OpenRouter/model-provider retention settings and terms.

## Phase 6: Mobile Network Hardening

- Use HTTPS-only production backend URLs.
- Remove local cleartext Android config from release builds or isolate it to debug builds.
- Consider certificate pinning after the production domain and certificate lifecycle are stable.
- Add a release checklist that verifies `PRODUCTION_BUILD=true`, `AI_PROVIDER=backend`, and no direct provider API keys are passed to Flutter.
