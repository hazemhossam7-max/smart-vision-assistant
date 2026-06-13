# Security Checklist

Use this checklist before building or releasing Smart Vision Assistant.

- Keep `OPENROUTER_API_KEY` only in `backend/.env` or the production secret manager.
- Do not pass `OPENROUTER_API_KEY` to Flutter release builds.
- Use `AI_PROVIDER=backend` for production builds.
- Use an HTTPS `BACKEND_BASE_URL` in production.
- Keep Privacy Mode on by default.
- Request microphone, camera, and location only when needed.
- Do not request Android storage permissions unless a future feature truly requires them.
- Do not log API keys, base64 images, full prompts, full transcripts, phone numbers, or precise coordinates.
- Keep backend rate limiting, vision endpoint limiting, payload validation, and OpenRouter timeouts enabled.
- Enable app integrity verification before public production release.
- Review and publish a privacy policy before public production release.
- Keep sensitive document warnings enabled unless the user explicitly disables them.
- Build release APKs with obfuscation and split debug info.

Recommended release command:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info \
  --dart-define=PRODUCTION_BUILD=true \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=https://your-production-backend.com \
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```
