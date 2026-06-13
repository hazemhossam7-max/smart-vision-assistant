# Smart Vision Assistant Threat Model

## Scope

This threat model covers the Flutter Android app, temporary camera frames, voice commands, secure settings, backend proxy, and OpenRouter integration.

## Primary Assets

- OpenRouter API key stored in backend environment only.
- Camera frames and selected keyframes.
- Spoken commands and assistant responses.
- Cloud AI consent state and privacy settings.
- Guardian/emergency contact values if added.
- Backend availability and OpenRouter spend/quota.

## Trust Boundaries

1. User device local app boundary.
2. Flutter app to backend HTTPS boundary.
3. Backend to OpenRouter HTTPS boundary.
4. Secure storage boundary on device.
5. Local temporary frame file boundary.

## Implemented Controls

- Backend proxy prevents OpenRouter API key from being shipped in the app.
- Backend validates allowed intents and selected frame count.
- Backend request limits and in-memory rate limiting are implemented.
- Optional backend client token is supported.
- Privacy Mode defaults on.
- Cloud consent is required before first cloud AI request.
- Selected frames are locally filtered before upload.
- Temporary frame files are deleted after processing when Privacy Mode is enabled.
- `flutter_secure_storage` stores security settings.
- `local_auth` protects sensitive settings/actions when enabled.
- OpenRouter requests include privacy routing options.
- System prompts treat text in images as untrusted.
- App logging redacts keys, tokens, and base64 images.
- Android root-risk checks are available in settings.
- Release build shrinking/minification is enabled.

## Key Threats and Status

| Threat | Current Control | Remaining Work |
| --- | --- | --- |
| API key extraction from APK | Backend proxy | Deploy backend and enforce backend provider for release |
| Image prompt injection | Strong system prompt | Add eval tests with malicious image text |
| Sensitive frame upload | Privacy guard and consent | Add face/PII redaction model before upload |
| Temporary frame leakage | Privacy mode cleanup | Validate all camera plugin temp paths on devices |
| Network interception | HTTPS production guard | Implement real certificate pin verification after stable domain |
| Backend abuse/cost spike | In-memory rate limit | Redis/shared rate limiter and per-user quotas |
| Device compromise/root | Basic root-risk signal | Add Play Integrity API and stronger tamper response |
| Sensitive settings access | local_auth for settings | Add recovery UX and security event audit |
| Emergency contact privacy | Secure storage key reserved | Design E2E encrypted contact storage/sync |
| Voice spoofing | None | True voice biometrics requires specialist model and threat review |

## Explicit Non-Goals for Current MVP

- True voice biometric authentication.
- Production-grade face/PII redaction.
- E2E encrypted cloud contact sync.
- Complete malware/root protection.
- Certificate pin verification without a stable production certificate.

## Release Security Checklist

- Build with `PRODUCTION_BUILD=true`.
- Use `AI_PROVIDER=backend`.
- Use HTTPS backend URL.
- Do not pass provider API keys to Flutter.
- Set backend `OPENROUTER_API_KEY` in secret manager/environment.
- Set backend `ENFORCE_HTTPS=true`.
- Configure real certificate pinning once the production domain is stable.
- Run `flutter analyze` and release build.
- Run penetration test checklist in `docs/security/PENTEST_REPORT.md`.
