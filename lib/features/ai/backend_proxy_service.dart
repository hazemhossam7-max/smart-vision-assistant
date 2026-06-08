import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';
import '../vision/frame_metadata.dart';
import '../voice/intent_classifier.dart';
import 'ai_service.dart';

class BackendProxyService implements AiService {
  const BackendProxyService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client? _client;
  final String? _baseUrl;

  @override
  Future<AiResponse> analyzeKeyframes({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
  }) async {
    if (selectedFrames.isEmpty) {
      return const AiResponse(
        provider: 'backend_no_frames',
        text: 'I could not find a good camera frame to analyze. Please try again.',
      );
    }

    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final endpoint = Uri.parse(
        '${(_baseUrl ?? AppConfig.backendBaseUrl).replaceFirst(RegExp(r'/$'), '')}/api/vision/analyze',
      );

      if (_isInsecureProductionUrl(endpoint)) {
        return const AiResponse(
          provider: 'backend_insecure_url',
          text: 'The production backend must use HTTPS. Please update the backend URL.',
        );
      }

      final response = await client.post(
        endpoint,
        headers: _headers,
        body: jsonEncode({
          'userCommand': userCommand,
          'intent': intent.label,
          'selectedFrames': await _selectedFramePayload(selectedFrames),
          'allFrames': allFrames.map(_frameMetadataPayload).toList(),
        }),
      );

      final decoded = _decodeJsonObject(response.body);
      final responseText = decoded?['text'];
      final responseProvider = decoded?['provider'];

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AiResponse(
          provider: 'backend_error_${response.statusCode}',
          text: responseText is String && responseText.trim().isNotEmpty
              ? responseText.trim()
              : 'The backend request failed with status ${response.statusCode}. Please try again.',
        );
      }

      return AiResponse(
        provider: responseProvider is String && responseProvider.trim().isNotEmpty
            ? responseProvider.trim()
            : 'backend',
        text: responseText is String && responseText.trim().isNotEmpty
            ? responseText.trim()
            : 'The backend returned an empty response. Please try again.',
      );
    } catch (_) {
      return const AiResponse(
        provider: 'backend_exception',
        text: 'The secure backend request failed. Please check that the backend is running and try again.',
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (AppConfig.backendClientToken.isNotEmpty) {
      headers['X-Client-Token'] = AppConfig.backendClientToken;
    }
    return headers;
  }

  bool _isInsecureProductionUrl(Uri endpoint) {
    if (!AppConfig.productionBuild || endpoint.scheme == 'https') {
      return false;
    }

    return endpoint.host != '127.0.0.1' && endpoint.host != 'localhost';
  }

  Future<List<Map<String, Object?>>> _selectedFramePayload(
    List<FrameMetadata> frames,
  ) async {
    final payload = <Map<String, Object?>>[];

    for (final frame in frames) {
      final bytes = await File(frame.filePath).readAsBytes();
      payload.add({
        ..._frameMetadataPayload(frame),
        'base64Image': base64Encode(bytes),
      });
    }

    return payload;
  }

  Map<String, Object?> _frameMetadataPayload(FrameMetadata frame) {
    return {
      'frameId': frame.frameId,
      'index': frame.index,
      'width': frame.width,
      'height': frame.height,
      'clarityScore': frame.clarityScore,
      'brightnessScore': frame.brightnessScore,
      'uniquenessScore': frame.uniquenessScore,
      'objectScore': frame.objectScore,
      'motionScore': frame.motionScore,
      'finalScore': frame.finalScore,
      'rejectionReasons': frame.rejectionReasons,
    };
  }

  Map<String, dynamic>? _decodeJsonObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
