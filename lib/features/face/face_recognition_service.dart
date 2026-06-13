import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_database_service.dart';
import 'face_embedding_service.dart';
import 'face_matcher.dart';

enum FaceRecognitionStatus {
  success,
  noFace,
  multipleFaces,
  noRegisteredFaces,
  unknown,
  modelMissing,
  storageError,
}

class FaceRecognitionResult {
  const FaceRecognitionResult({
    required this.status,
    this.name,
    this.score,
  });

  final FaceRecognitionStatus status;
  final String? name;
  final double? score;

  bool get isSuccess => status == FaceRecognitionStatus.success;
  bool get isUnknown => status == FaceRecognitionStatus.unknown;
}

class FaceRecognitionService {
  FaceRecognitionService({
    FaceDetector? faceDetector,
    FaceEmbeddingService? embeddingService,
    FaceDatabaseService databaseService = const FaceDatabaseService(),
    FaceMatcher matcher = const FaceMatcher(),
  })  : _faceDetector = faceDetector ??
            FaceDetector(
              options: FaceDetectorOptions(
                enableClassification: true,
                enableLandmarks: true,
                performanceMode: FaceDetectorMode.accurate,
              ),
            ),
        _embeddingService = embeddingService ?? FaceEmbeddingService(),
        _databaseService = databaseService,
        _matcher = matcher;

  final FaceDetector _faceDetector;
  final FaceEmbeddingService _embeddingService;
  final FaceDatabaseService _databaseService;
  final FaceMatcher _matcher;

  Future<FaceRecognitionResult> registerFace({
    required XFile frameFile,
    required String name,
  }) async {
    final faceResult = await _singleFace(frameFile);
    if (faceResult.status != FaceRecognitionStatus.success) {
      return faceResult;
    }

    try {
      final embedding = await _embeddingService.generateEmbedding(
        frameFile: frameFile,
        faceBounds: faceResult._face!.boundingBox,
      );
      await _databaseService.saveFaceSample(name: name, embedding: embedding);
      return FaceRecognitionResult(
        status: FaceRecognitionStatus.success,
        name: name,
      );
    } on FaceEmbeddingException {
      return const FaceRecognitionResult(
          status: FaceRecognitionStatus.modelMissing);
    } catch (_) {
      return const FaceRecognitionResult(
          status: FaceRecognitionStatus.storageError);
    }
  }

  Future<FaceRecognitionResult> recognizeFace({
    required XFile frameFile,
  }) async {
    try {
      final hasRegisteredFaces = await _databaseService.hasRegisteredFaces;
      if (!hasRegisteredFaces) {
        return const FaceRecognitionResult(
          status: FaceRecognitionStatus.noRegisteredFaces,
        );
      }
    } catch (_) {
      return const FaceRecognitionResult(
          status: FaceRecognitionStatus.storageError);
    }

    final faceResult = await _singleFace(frameFile);
    if (faceResult.status != FaceRecognitionStatus.success) {
      return faceResult;
    }

    try {
      final embedding = await _embeddingService.generateEmbedding(
        frameFile: frameFile,
        faceBounds: faceResult._face!.boundingBox,
      );
      final match = _matcher.findBestMatch(
        embedding: embedding,
        registeredFaces: await _databaseService.loadFaces(),
      );

      if (!match.isMatch) {
        return FaceRecognitionResult(
          status: FaceRecognitionStatus.unknown,
          name: match.name,
          score: match.score,
        );
      }

      return FaceRecognitionResult(
        status: FaceRecognitionStatus.success,
        name: match.name,
        score: match.score,
      );
    } on FaceEmbeddingException {
      return const FaceRecognitionResult(
          status: FaceRecognitionStatus.modelMissing);
    } catch (_) {
      return const FaceRecognitionResult(
          status: FaceRecognitionStatus.storageError);
    }
  }

  Future<_SingleFaceResult> _singleFace(XFile frameFile) async {
    final inputImage = InputImage.fromFilePath(frameFile.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      return const _SingleFaceResult(status: FaceRecognitionStatus.noFace);
    }
    if (faces.length > 1) {
      return const _SingleFaceResult(
          status: FaceRecognitionStatus.multipleFaces);
    }

    return _SingleFaceResult(
      status: FaceRecognitionStatus.success,
      face: faces.first,
    );
  }

  Future<void> close() async {
    await _faceDetector.close();
    _embeddingService.close();
  }
}

class _SingleFaceResult extends FaceRecognitionResult {
  const _SingleFaceResult({
    required super.status,
    Face? face,
  }) : _face = face;

  final Face? _face;
}
