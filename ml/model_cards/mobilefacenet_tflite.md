# MobileFaceNet TFLite Model

This project uses `assets/models/mobilefacenet.tflite` for local face
embedding generation.

## Source

- Repository: https://github.com/MCarlomagno/FaceRecognitionAuth
- Asset path upstream: `assets/mobilefacenet.tflite`
- License: BSD 3-Clause
- Copyright: Copyright (c) 2020, Marcos Carlomagno

## Expected Tensor Shapes

- Input: `1 x 112 x 112 x 3`
- Input normalization: `(channel - 127.5) / 128.0`
- Output: `1 x 192`

## Privacy

The model runs on-device. Generated embeddings and saved names are stored
locally and are not uploaded to the backend, Gemini, or OpenRouter. Only a
recognized display name can be attached to the visual AI prompt as text context.

## Notes

Accuracy depends on lighting, camera quality, face angle, and registration
samples. Registering more than one sample for the same person can improve
matching reliability.
