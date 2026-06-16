# Security Checklist

Use this checklist before building or releasing Smart Vision Assistant.

- Keep `OPENROUTER_API_KEY` only in `backend/.env` or the production secret manager.
- Do not pass `OPENROUTER_API_KEY`, `OPENAI_API_KEY`, or `GEMINI_API_KEY` to Flutter release builds.
- Use `AI_PROVIDER=backend` for production builds.
- Use an HTTPS `BACKEND_BASE_URL` in production.
- Keep Android cleartext networking restricted to localhost/127.0.0.1 for development.
- Keep iOS ATS local networking exceptions for development only; production must use HTTPS.
- Keep Privacy Mode on by default.
- Request microphone, camera, and location only when needed.
- Do not request Android storage permissions unless a future feature truly requires them.
- Do not log API keys, base64 images, full prompts, full transcripts, phone numbers, or precise coordinates.
- Keep backend rate limiting, vision endpoint limiting, payload validation, Helmet headers, and OpenRouter timeouts enabled.
- Enable real app integrity verification before public production release.
- Review and publish a privacy policy before public production release.
- Keep sensitive document warnings enabled unless the user explicitly disables them.
- Treat Face/PII redaction as scaffolded only until real on-device redaction is implemented and tested.
- Build release APKs/IPAs with obfuscation and split debug info.
- Scan APK and IPA binaries for leaked API keys before release.

Recommended Android release command:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info \
  --dart-define=PRODUCTION_BUILD=true \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=https://your-production-backend.com \
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```

Recommended iOS release command on macOS:

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info \
  --dart-define=PRODUCTION_BUILD=true \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=https://your-production-backend.com \
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```

APK secret scan on Windows:

```powershell
strings build/app/outputs/flutter-apk/app-release.apk | findstr /I "OPENROUTER OPENAI GEMINI API_KEY sk- Bearer"
```

APK secret scan on macOS/Linux:

```bash
strings build/app/outputs/flutter-apk/app-release.apk | grep -Ei "OPENROUTER|OPENAI|GEMINI|API_KEY|sk-|Bearer"
```

IPA secret scan on macOS/Linux:

```bash
unzip build/ios/ipa/*.ipa -d ipa_extract
strings ipa_extract/Payload/Runner.app/Runner | grep -Ei "OPENROUTER|OPENAI|GEMINI|API_KEY|sk-|Bearer"
```

Expected result: no real API keys should appear. Harmless constant names may appear.
