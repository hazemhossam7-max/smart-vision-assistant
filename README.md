# Smart Vision Assistant

Flutter Android/iOS MVP for a graduation project focused on voice-controlled
visual assistance for blind users.

The app listens for a spoken command, classifies the command into a vision
intent, captures a burst of camera frames, scores the frames locally, selects
the best keyframes, then sends only those selected keyframes to a multimodal AI
model. The secure development path sends them through the backend proxy so the
OpenRouter API key stays off the mobile app.

## MVP Flow

1. The user presses the large microphone button.
2. Speech is converted to text using `speech_to_text`.
3. The command is classified into one of the supported intents.
4. Emergency/SOS commands open the phone or SMS confirmation flow without camera capture.
5. Vision commands request camera/location only when needed.
6. The camera captures a short burst of frames.
7. Each frame is scored locally using clarity, brightness, uniqueness, object importance, and motion/change.
8. Bad frames are filtered out.
9. The top 3 keyframes are selected.
10. The backend proxy receives only selected frames plus metadata and calls OpenRouter.
11. The response is spoken with TTS and displayed on screen.

## Supported Intents

- `scene_description`
- `text_reading`
- `object_search`
- `obstacle_detection`
- `navigation_help`
- `currency_recognition`
- `emergency_help`
- `face_registration`
- `face_recognition`

## Local Keyframe Retrieval

Each captured frame is scored locally before any AI request:

- Clarity using Laplacian variance / blur estimation
- Brightness using average luminance
- Uniqueness using average image hash distance
- Motion/change using frame-to-frame hash distance
- Object-importance heuristic
- Weighted final score
- Blur/dark/bright/duplicate rejection

The app currently captures a short burst and selects the top 3 keyframes.

## Security and Privacy

- Privacy Mode defaults to on.
- The app asks for Cloud AI consent before the first backend/cloud analysis.
- Sensitive text-reading commands show a warning before capturing IDs, cards, passwords, or medical papers.
- Cloud consent and privacy settings are stored with `flutter_secure_storage`.
- Selected keyframes are filtered by `PrivacyGuardService` before upload.
- Temporary camera frame files are deleted after the pipeline finishes when Privacy Mode is enabled.
- Microphone, camera, and location permissions are requested only when needed for the current action.
- The Security & Privacy screen protects sensitive actions with device biometric/PIN auth when enabled.
- Guardian contact is stored securely and used only to open call/SMS confirmation for Emergency/SOS mode.
- OpenRouter requests ask for privacy-conscious routing with `provider.data_collection=deny` and `provider.zdr=true`.
- The backend is the secure production path. Direct OpenRouter remains only for demos/testing.
- Backend responses include request IDs so support/debugging does not require logging image payloads.
- Backend app-integrity enforcement is available behind `REQUIRE_APP_INTEGRITY=true` for production hardening.

## Egyptian Currency Model

This repo includes the upstream Egyptian currency YOLOv8 weights from:

https://github.com/A7MEDELRAGGAL/Egyptian-Currency-System

Local files:

- `assets/models/egyptian_currency_yolov8.pt`
- `assets/models/egyptian_currency_labels.json`
- `ml/model_cards/egyptian_currency_yolov8.md`

Reported upstream metrics:

- Precision: 99.89%
- Recall: 100%
- mAP50: 99.5%
- mAP50-95: 99.07%

Important: the included model is a PyTorch `.pt` artifact. Flutter on-device
inference should use an exported `.tflite` file. The model card includes the
recommended export command and expected asset path.

## Local Face Recognition

Face registration and matching run on the device. The app uses ML Kit face
detection to find one face in the camera frame, crops that face locally, then
uses a MobileFaceNet/FaceNet-style TensorFlow Lite model to generate an
embedding. Saved names and embeddings are stored in the app documents directory
as `registered_faces.json`.

Privacy notes:

- Face embeddings and saved names are not uploaded to Gemini, OpenRouter, or the backend.
- Only the recognized name, for example `Adham`, is added as text context to the visual AI prompt.
- Registration does not use cloud analysis or cloud consent.

Supported voice examples:

- `Register this face`
- `Save this face`
- `Remember this person`
- `Register this face as Adham`
- `This is Adham`
- `Who is in front of me?`
- `Who is standing in front of me?`
- `Who is here?`
- `Who is beside me?`
- `Who is shouting in front of me?`
- `Describe the person in front of me`

Expected model file:

- Path: `assets/models/mobilefacenet.tflite`
- Input: one RGB face crop, `112 x 112 x 3`, float normalized with `(value - 127.5) / 128.0`
- Output: one embedding vector, currently configured as 192 floats

This repository includes only a placeholder at that path. Replace it with a real
MobileFaceNet/FaceNet `.tflite` model before running face registration on a
device. If your model uses a different input size or embedding length, update
`FaceEmbeddingService` in `lib/features/face/face_embedding_service.dart`.

The asset is declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/mobilefacenet.tflite
```

After replacing the model:

```bash
flutter pub get
flutter run
```

Manual test flow:

1. Put one person clearly in front of the camera.
2. Tap the microphone and say `Register this face as Adham`.
3. Wait for `Adham has been registered successfully.`
4. Close and reopen the app to confirm persistence.
5. Tap the microphone and say `Who is in front of me?`
6. The app should identify the saved local face and include `Adham` in the spoken answer.

## Backend Proxy

For the secure provider path, put secrets only in `backend/.env`:

```bash
cd backend
copy .env.example .env
```

Then edit `backend/.env` and set:

```env
OPENROUTER_API_KEY=your_openrouter_key
BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```

Do not pass `OPENROUTER_API_KEY` to Flutter. The backend token is not a full
replacement for user auth or device attestation, but it prevents anonymous
backend calls when configured.

Terminal 1:

```bash
cd backend
npm install
node server.js
```

Health check:

```bash
curl http://127.0.0.1:3000/health
```

Terminal 2 for a real Android device:

```bash
adb devices
adb -s 07748251CL002087 reverse tcp:3000 tcp:3000
flutter run -d 07748251CL002087 ^
  --dart-define=AI_PROVIDER=backend ^
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:3000 ^
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```

Production should use an HTTPS backend URL instead of local cleartext HTTP.

## Backend Deployment

The backend includes a production Dockerfile:

```bash
cd backend
docker build -t smart-vision-assistant-backend .
docker run --rm -p 3000:3000 \
  -e NODE_ENV=production \
  -e OPENROUTER_API_KEY=your_openrouter_key \
  -e BACKEND_CLIENT_TOKEN=make_this_a_long_random_value \
  -e ENFORCE_HTTPS=true \
  -e TRUST_PROXY=true \
  smart-vision-assistant-backend
```

In production, terminate HTTPS at a trusted host, reverse proxy, or load
balancer, then forward requests to the container. Set `TRUST_PROXY=true` only
when that proxy is trusted and it sends `X-Forwarded-Proto`. The backend refuses
to start with `NODE_ENV=production` unless `OPENROUTER_API_KEY`,
`BACKEND_CLIENT_TOKEN`, and `ENFORCE_HTTPS=true` are configured.

Set `REQUIRE_APP_INTEGRITY=true` only after replacing the current scaffold with
real Firebase App Check or Play Integrity verification.

## API Keys

No API keys are hardcoded. The recommended provider is the backend proxy:

```bash
flutter run \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:3000 \
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value
```

Direct providers remain available for demos/testing. For example:

```bash
flutter run -d 07748251CL002087 \
  --dart-define=AI_PROVIDER=openrouter \
  --dart-define=OPENROUTER_API_KEY=your_openrouter_key \
  --dart-define=OPENROUTER_MODEL=google/gemini-2.5-flash
```

For production builds, force the backend provider and HTTPS backend URL:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info \
  --dart-define=PRODUCTION_BUILD=true \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=https://your-backend.example.com \
  --dart-define=BACKEND_CLIENT_TOKEN=make_this_a_long_random_value \
  --dart-define=REQUIRE_CERTIFICATE_PINNING=true \
  --dart-define=BACKEND_CERT_SHA256=your_backend_spki_sha256 \
  --dart-define=REQUIRE_IMAGE_REDACTION=true
```

`REQUIRE_IMAGE_REDACTION=true` should stay enabled for public production until
real on-device face/PII redaction is implemented. Production backend environment
should set `ENFORCE_HTTPS=true`, keep secrets in the host secret manager or
environment settings, and avoid committing `.env`. See `SECURITY_PIPELINE.md`
and `SECURITY_CHECKLIST.md` for the remaining hardening plan.

## Platform Setup

If this folder was not created with `flutter create`, run this once after installing Flutter:

```bash
flutter create --platforms=android,ios .
```

Then add camera and microphone permission descriptions to the generated platform files:

- Android: `android/app/src/main/AndroidManifest.xml`
  - `android.permission.CAMERA`
  - `android.permission.RECORD_AUDIO`
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.ACCESS_COARSE_LOCATION`
  - `android.permission.USE_BIOMETRIC`
- iOS: `ios/Runner/Info.plist`
  - `NSCameraUsageDescription`
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`

## Verify

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
