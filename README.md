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
4. The camera captures a short burst of frames.
5. Each frame is scored locally using clarity, brightness, uniqueness, object importance, and motion/change.
6. Bad frames are filtered out.
7. The top 3 keyframes are selected.
8. The backend proxy receives only selected frames plus metadata and calls OpenRouter.
9. The response is spoken with TTS and displayed on screen.

## Supported Intents

- `scene_description`
- `text_reading`
- `object_search`
- `obstacle_detection`
- `navigation_help`
- `currency_recognition`

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

## Backend Proxy

For the secure provider path, put the OpenRouter API key only in `backend/.env`:

```bash
cd backend
copy .env.example .env
```

Then edit `backend/.env` and set `OPENROUTER_API_KEY`. Do not pass
`OPENROUTER_API_KEY` to Flutter when using the backend provider.

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
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:3000
```

Production should use an HTTPS backend URL instead of local cleartext HTTP.

## API Keys

No API keys are hardcoded. The recommended provider is the backend proxy:

```bash
flutter run \
  --dart-define=AI_PROVIDER=backend \
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:3000
```

Direct providers remain available for demos/testing. For example:

```bash
flutter run -d 07748251CL002087 \
  --dart-define=AI_PROVIDER=openrouter \
  --dart-define=OPENROUTER_API_KEY=your_openrouter_key \
  --dart-define=OPENROUTER_MODEL=google/gemini-2.5-flash
```

For production, call OpenRouter through a backend proxy. Mobile API keys can be
extracted from APK/IPA files.

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
