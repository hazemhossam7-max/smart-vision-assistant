# Security Pipeline

This pipeline tracks the move from a demo mobile AI integration to a safer production architecture.

## Phase 1: Backend Proxy Hardening - Implemented

- Move OpenRouter API access out of Flutter and into `backend/server.js`.
- Read `OPENROUTER_API_KEY` from backend environment only.
- Add `BACKEND_CLIENT_TOKEN` support.
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

## Phase 3: OpenRouter Privacy Settings and Prompt Injection Protection - Implemented MVP

- Add OpenRouter provider routing options:
  - `data_collection: deny`
  - `zdr: true`
- Strengthen backend and direct fallback system prompts against image prompt injection.
- Avoid returning raw OpenRouter error bodies to Flutter.
- Continue treating backend as the secure production path and direct OpenRouter as demo/testing only.

## Phase 4: Secure App Settings - Implemented MVP

- Add `flutter_secure_storage`.
- Add `SecureStorageService` wrapper so secure storage is not used directly throughout the app.
- Add `SecuritySettingsService` with secure defaults.
- Ask for Cloud AI consent before the first backend/cloud analysis and store the result securely.

## Phase 5: Biometric/PIN Protection - Implemented MVP

- Add `local_auth`.
- Add `LocalAuthService` with device biometric/PIN fallback.
- Add a Security & Privacy screen for Privacy Mode, Save History, Cloud Consent status, Biometric Lock, and Delete Local Data.
- Require authentication for sensitive settings/actions when appropriate.
- Keep the main microphone/camera flow fast and unlocked for accessibility.

## Phase 6: Logging Review - Implemented MVP

- Centralize app logs through `LoggerService`.
- Redact API keys, backend tokens, and base64 images.
- Suppress app demo logs in production builds.
- Keep backend logs generic and avoid raw OpenRouter error bodies.

## Phase 7: APK Hardening - Started

- Enable Android release minification/resource shrinking with R8/ProGuard.
- Add conservative ProGuard keep rules for Flutter and local auth.
- Release builds should also use Flutter obfuscation:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

## Phase 8: Root Detection - Implemented Basic Signal

- Add Android method-channel root-risk checks for test-keys and common `su` paths.
- Show device integrity status in Security & Privacy settings.
- Block Save History on root-risk devices and automatically disable it if a root-risk signal appears.
- Pending: Play Integrity API or stronger attestation for production decisions.

## Phase 9: AI Safety Moderation Layer - Implemented MVP

- Add local command moderation for obviously unsafe requests.
- Add response moderation for unsafe navigation certainty phrases.
- Add backend-side prompt moderation for high-risk requests before calling OpenRouter.
- Pending: model-based moderation, policy tests, and safety eval suite.

## Phase 10: Certificate Pinning - Guard Added, Verification Pending

- Add production flags:
  - `REQUIRE_CERTIFICATE_PINNING`
  - `BACKEND_CERT_SHA256`
- Fail closed if production requires pinning but no pin is configured.
- Pending: implement runtime certificate/SPKI verification after a stable production backend domain and certificate lifecycle exist.

## Phase 11: Face/PII Redaction Before Upload - Pending

- Required before public production for camera frames in sensitive settings.
- Recommended implementation:
  - On-device face detection / ML Kit.
  - Blur faces and sensitive text regions before upload when privacy mode is on.
  - Preserve accessibility value by sending redacted but still useful keyframes.
- Do not ship a fake redaction toggle without real redaction.

## Phase 12: Voice Biometric Authentication - Pending / Needs Specialist Design

- Current app uses device biometric/PIN via `local_auth`.
- True voice biometrics needs enrollment, anti-spoofing/liveness, secure templates, and false reject/accessibility review.
- Do not use simple voice matching as an authentication control.

## Phase 13: End-to-End Encrypted Emergency Contact System - Pending

- Current secure settings reserve a guardian phone key for future local storage.
- E2E encrypted sync/contact workflow needs:
  - Key generation and rotation.
  - Contact verification.
  - Lost-device recovery.
  - Encrypted backup policy.
  - Abuse prevention for emergency messaging.

## Phase 14: Production Deployment - Pending

- Deploy the backend behind HTTPS using a managed platform or reverse proxy.
- Set production environment variables in the host platform, not in committed files.
- Set `ENFORCE_HTTPS=true`.
- Set `TRUST_PROXY=true` only when the backend is behind a trusted proxy/load balancer.
- Configure domain allowlists and network firewall rules where available.
- Add health checks and uptime monitoring for `/health`.

## Phase 15: Stronger Authentication - Pending

`BACKEND_CLIENT_TOKEN` is a first production gate, but a static mobile token can still be extracted from an APK/IPA. Upgrade to one of these before public release:

- User login with short-lived backend-issued tokens.
- Device attestation such as Play Integrity API / App Attest.
- Per-user quotas and revocation.
- Server-side session auditing.

## Phase 16: Abuse and Cost Controls - Started

- Add backend in-memory rate limiting.
- Add a configurable in-memory daily request quota with `DAILY_QUOTA_MAX_REQUESTS`.
- Pending: replace in-memory controls with Redis or a managed rate-limit/quota service for multi-instance deployments.
- Pending: add per-user, per-device, and per-IP quotas backed by authenticated identity.
- Pending: add OpenRouter spend caps, alerting, and cost dashboards.
- Pending: add request IDs to backend logs, but never log API keys or base64 images.

## Phase 17: Privacy and Data Governance - Pending

- Publish a privacy policy explaining camera frame processing and third-party AI processing.
- Add explicit user consent copy to onboarding if onboarding is added.
- Avoid storing image frames unless a user explicitly opts in.
- Define retention rules for logs and metadata.
- Review OpenRouter/model-provider retention settings and terms.

## Phase 18: Threat Model and Penetration Testing - Started

- Add `docs/security/THREAT_MODEL.md`.
- Add `docs/security/PENTEST_REPORT.md` template/checklist.
- Pending: execute tests, record evidence, and close findings.
