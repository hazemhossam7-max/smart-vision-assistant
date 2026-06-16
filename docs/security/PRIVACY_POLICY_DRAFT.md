# Privacy Policy Draft

This draft is a starting point for legal/product review before public release. Do not publish it unchanged without confirming the deployed backend, model provider, retention settings, and local laws that apply to the app.

## Placeholders To Complete

- Support email: `TODO_SUPPORT_EMAIL`
- Production backend domain: `TODO_BACKEND_DOMAIN`
- Log retention period: `TODO_LOG_RETENTION_PERIOD`
- Data deletion request process: `TODO_DELETION_PROCESS`
- Model provider/OpenRouter retention terms reviewed on: `TODO_REVIEW_DATE`

## What The App Does

Smart Vision Assistant helps blind and visually impaired users understand their surroundings. The app listens to a spoken command, captures a short camera burst, selects the clearest keyframes locally, and sends only selected keyframes to the configured AI backend for analysis.

## Data Processed

The app may process:

- Spoken commands converted to text on the device.
- Temporary camera frames captured for the requested visual task.
- Frame quality metadata such as brightness, clarity, and frame score.
- Security and privacy settings stored locally on the device.
- Guardian phone number stored locally if the user adds one.
- Backend request metadata such as request ID, status code, duration, and rate-limit counters.

## Camera Images

Privacy Mode is enabled by default. When Privacy Mode is enabled, temporary camera frame files are deleted after the request finishes. The app filters weak or rejected frames before upload and sends only selected keyframes to the backend.

Current image storage statement: `TODO_CONFIRM_IMAGE_STORAGE`. The intended behavior is that image frames are temporary and deleted locally when Privacy Mode is enabled. The backend should not persist uploaded image data.

The current implementation includes a Face/PII redaction scaffold, but does not yet perform full face or sensitive text redaction before upload. Public production release should keep `REQUIRE_IMAGE_REDACTION=true` until real on-device redaction is implemented and tested.

## Voice Commands And Transcripts

Spoken commands are converted to text to classify the request and build the AI prompt. Current transcript storage statement: `TODO_CONFIRM_TRANSCRIPT_STORAGE`. The intended behavior is not to store full transcripts in logs or persistent history unless a future user-controlled feature explicitly enables it.

## Cloud AI Processing

When the backend provider is used, selected keyframes and prompt metadata are sent to the production backend at `TODO_BACKEND_DOMAIN`, and the backend sends them to the configured model provider through OpenRouter. OpenRouter requests are configured with privacy-conscious provider routing options where supported:

- `data_collection: deny`
- `zdr: true`

These settings depend on provider support and should be reviewed against OpenRouter and model-provider terms before production launch.

## Emergency And Guardian Contact

If the user adds a guardian phone number, it is stored in secure device storage where available. Emergency/SOS mode opens the phone or SMS app for user confirmation; it should not silently place calls or send SMS messages.

Location is requested only for navigation help or emergency sharing when requested. Current emergency location sharing statement: `TODO_CONFIRM_LOCATION_SHARING`. The current demo SMS text does not include precise coordinates.

## Secrets And Authentication

OpenRouter API keys are stored only on the backend. The mobile app should never include the OpenRouter API key. Production builds should use the backend provider over HTTPS and should not enable direct AI providers except for controlled demos.

## Local Settings And Secure Storage

Security and privacy settings are stored using secure device storage where available. These include cloud consent, Privacy Mode, Save History preference, biometric/PIN lock preference, sensitive document warning preference, and guardian contact settings.

## Consent And User Choices

Users should be able to:

- Grant or deny Cloud AI consent.
- Keep Privacy Mode enabled.
- Keep sensitive document warnings enabled.
- Disable Save History.
- Add, update, or remove guardian contact details.
- Delete local app data from the Security & Privacy screen.

## Logs

The app and backend should not log API keys, backend tokens, base64 image data, full prompts, full voice transcripts, guardian phone numbers, or precise location coordinates. Backend production logs should use request IDs and operational metadata only.

Log retention period: `TODO_LOG_RETENTION_PERIOD`.

## Data Deletion

Users can delete local app data from the Security & Privacy screen. Production support should also provide a deletion request process: `TODO_DELETION_PROCESS`.

## Production Requirements Before Publishing

Before publishing this policy, confirm and document:

- The production backend domain and hosting provider.
- The model provider and OpenRouter retention behavior.
- Whether image redaction is enabled and how it works.
- Whether images are stored or deleted by the backend.
- Whether transcripts are stored or deleted.
- Log retention periods.
- User support/contact email.
- Data deletion request process.
- Regional legal requirements for the target users.
