# Production Security Guide

## Android Development

Terminal 1:

```bash
cd backend
npm install
node server.js
```

Terminal 2:

```bash
adb devices
adb -s 07748251CL002087 reverse tcp:3000 tcp:3000
flutter run -d 07748251CL002087 \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:3000
```

Android cleartext HTTP is restricted to `127.0.0.1` and `localhost` in `network_security_config.xml` for local development only.

## iOS Simulator Development

Terminal 1:

```bash
cd backend
npm install
node server.js
```

Run:

```bash
flutter run -d ios \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:3000
```

`NSAllowsLocalNetworking` is enabled for local development. Production must use HTTPS.

## iOS Physical Device Development

Use the laptop LAN IP or a deployed HTTPS backend:

```bash
flutter run -d <ios-device-id> \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=http://192.168.1.X:3000
```

Ensure the laptop firewall allows inbound connections to the backend port. Production builds must use HTTPS.

## Production Android And iOS Builds

Use the backend provider and HTTPS backend URL:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info \
  --dart-define=PRODUCTION_BUILD=true \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=https://your-production-backend.com \
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```

For iOS on macOS:

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info \
  --dart-define=PRODUCTION_BUILD=true \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=https://your-production-backend.com \
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```

Never pass these keys to Flutter release builds:

```bash
--dart-define=OPENROUTER_API_KEY=...
--dart-define=OPENAI_API_KEY=...
--dart-define=GEMINI_API_KEY=...
```

## Android Signing

Copy the signing template locally:

```bash
copy android\key.properties.example android\key.properties
```

Fill `android/key.properties` with local signing values. Do not commit `android/key.properties`, `.jks`, or `.keystore` files.

## Backend Production Hardening

- Deploy the backend behind HTTPS.
- Store environment variables in hosting provider secrets, not committed files.
- Set `NODE_ENV=production`.
- Set `ENFORCE_HTTPS=true`.
- Set `TRUST_PROXY=true` only behind a trusted reverse proxy/load balancer.
- Restrict `CORS_ALLOWED_ORIGINS` if a browser client is added.
- Use Redis or a managed rate-limit service for multi-instance deployments.
- Enable real app integrity verification before public release.
- Add uptime monitoring for `/health`.
- Add spending alerts and caps for OpenRouter.
- Keep logs free of API keys, base64 images, full prompts, transcripts, guardian phone numbers, and precise coordinates.

## Verification Commands

```bash
flutter pub get
flutter analyze
flutter test
cd backend
npm install
node server.js
curl http://127.0.0.1:3000/health
```
