# Privacy Policy Draft

This draft is a starting point for legal/product review before public release. Do not publish it unchanged without confirming the deployed backend, model provider, retention settings, and local laws that apply to the app.

## What The App Does

Smart Vision Assistant helps blind and visually impaired users understand their surroundings. The app listens to a spoken command, captures a short camera burst, selects the clearest keyframes locally, and sends only selected keyframes to the configured AI backend for analysis.

## Data Processed

The app may process:

- Spoken commands converted to text on the device.
- Temporary camera frames captured for the requested visual task.
- Frame quality metadata such as brightness, clarity, and frame score.
- Security and privacy settings stored locally on the device.
- Backend request metadata such as request ID, status code, duration, and rate-limit counters.

## Camera Images

Privacy Mode is enabled by default. When Privacy Mode is enabled, temporary camera frame files are deleted after the request finishes. The app filters weak or rejected frames before upload and sends only selected keyframes to the backend.

The current implementation does not yet perform full face or sensitive text redaction before upload. Public production release should keep `REQUIRE_IMAGE_REDACTION=true` until real on-device redaction is implemented and tested.

## Cloud AI Processing

When the backend provider is used, selected keyframes and prompt metadata are sent to the backend, and the backend sends them to the configured model provider through OpenRouter. OpenRouter requests are configured with privacy-conscious provider routing options where supported:

- `data_collection: deny`
- `zdr: true`

These settings depend on provider support and should be reviewed against OpenRouter and model-provider terms before production launch.

## Secrets And Authentication

OpenRouter API keys are stored only on the backend. The mobile app should never include the OpenRouter API key. Production builds should use the backend provider over HTTPS and should not enable direct AI providers except for controlled demos.

## Local Settings

Security and privacy settings are stored using secure device storage where available. These include cloud consent, Privacy Mode, Save History preference, biometric/PIN lock preference, and reserved future guardian-contact settings.

## Logs

The app and backend should not log API keys, backend tokens, or base64 image data. Backend production logs should use request IDs and operational metadata only. Logs should have a defined retention period before public release.

## User Choices

Users should be able to:

- Grant or deny Cloud AI consent.
- Keep Privacy Mode enabled.
- Disable Save History.
- Delete local app data from the Security & Privacy screen.

## Production Requirements Before Publishing

Before publishing this policy, confirm and document:

- The production backend domain and hosting provider.
- The model provider and OpenRouter retention behavior.
- Whether image redaction is enabled and how it works.
- Log retention periods.
- User support/contact email.
- Data deletion request process.
- Regional legal requirements for the target users.
