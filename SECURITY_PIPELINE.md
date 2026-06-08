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

## Phase 2: Privacy-Safe Frame Handling - Implemented MVP

- Add `PrivacyGuardService` to reject weak, rejected, underexposed, overexposed, or low-score frames before upload.
- Send only privacy-safe selected keyframes to the AI service.
- Stop the cloud request and speak a short accessible message when no safe frames remain.
- Add `TemporaryFrameCleanupService` to delete temporary captured frame files after the pipeline finishes.
- Keep Privacy Mode on by default so temporary image files are not kept after response.

## Phase 3: OpenRouter Privacy Settings - Implemented MVP

- Add OpenRouter provider routing options:
  - `data_collection: deny`
  - `zdr: true`
- Strengthen backend and direct fallback system prompts against image prompt injection.
- Avoid returning raw OpenRouter error bodies to Flutter.
- Continue treating backend as the secure production path and direct OpenRouter as demo/testing only.

## Phase 4: Secure App Settings - Implemented MVP

- Add `flutter_secure_storage`.
- Add `SecureStorageService` wrapper so secure storage is not used directly throughout the app.
- Add `SecuritySettingsService` with secure defaults:
  - `privacy_mode_enabled`: true
  - `cloud_consent_given`: false
  - `save_history_enabled`: false
  - `biometric_lock_enabled`: false
- Ask for Cloud AI consent before the first backend/cloud analysis and store the result securely.

## Phase 5: Biometric/PIN Protection - Implemented MVP

- Add `local_auth`.
- Add `LocalAuthService` with device biometric/PIN fallback.
- Add a Security & Privacy screen for Privacy Mode, Save History, Cloud Consent status, Biometric Lock, and Delete Local Data.
- Require authentication for sensitive settings/actions when appropriate.
- Keep the main microphone/camera flow fast and unlocked for accessibility.

## Phase 6: Production Deployment - Pending

- Deploy the backend behind HTTPS using a managed platform or reverse proxy.
- Set production environment variables in the host platform, not in committed files.
- Set `ENFORCE_HTTPS=true`.
- Set `TRUST_PROXY=true` only when the backend is behind a trusted proxy/load balancer.
- Configure domain allowlists and network firewall rules where available.
- Add health checks and uptime monitoring for `/health`.

## Phase 7: Stronger Authentication - Pending

`BACKEND_CLIENT_TOKEN` is a first production gate, but a static mobile token can still be extracted from an APK/IPA. Upgrade to one of these before public release:

- User login with short-lived backend-issued tokens.
- Device attestation such as Play Integrity API / App Attest.
- Per-user quotas and revocation.
- Server-side session auditing.

## Phase 8: Abuse and Cost Controls - Pending

- Replace in-memory rate limiting with Redis or a managed rate limit service for multi-instance deployments.
- Add per-user, per-device, and per-IP quotas.
- Add daily spend caps for OpenRouter calls.
- Add alerting for spikes, repeated validation failures, and high-cost usage.
- Add request IDs to backend logs, but never log API keys or base64 images.

## Phase 9: Privacy and Data Governance - Pending

- Publish a privacy policy explaining camera frame processing and third-party AI processing.
- Add explicit user consent copy to onboarding if onboarding is added.
- Avoid storing image frames unless a user explicitly opts in.
- Define retention rules for logs and metadata.
- Review OpenRouter/model-provider retention settings and terms.

## Phase 10: Mobile Network Hardening - Pending

- Use HTTPS-only production backend URLs.
- Remove local cleartext Android config from release builds or isolate it to debug builds.
- Consider certificate pinning after the production domain and certificate lifecycle are stable.
- Add a release checklist that verifies `PRODUCTION_BUILD=true`, `AI_PROVIDER=backend`, and no direct provider API keys are passed to Flutter.
