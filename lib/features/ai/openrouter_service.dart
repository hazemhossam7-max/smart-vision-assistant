import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';
import '../../core/security/prompt_security_service.dart';
import '../currency/egyptian_currency_model.dart';
import '../vision/frame_metadata.dart';
import '../voice/intent_classifier.dart';
import 'ai_service.dart';

class OpenRouterService implements AiService {
  const OpenRouterService({
    http.Client? client,
    PromptSecurityService promptSecurityService = const PromptSecurityService(),
  })  : _client = client,
        _promptSecurityService = promptSecurityService;

  final http.Client? _client;
  final PromptSecurityService _promptSecurityService;

  static final Uri _endpoint = Uri.parse(
    'https://openrouter.ai/api/v1/chat/completions',
  );

  @override
  Future<AiResponse> analyzeKeyframes({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
    String? knownFaceName,
  }) async {
    const apiKey = AppConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      return const AiResponse(
        provider: 'openrouter_no_key',
        text:
            'OpenRouter is selected, but no API key was provided. Run the app with OPENROUTER_API_KEY.',
      );
    }

    if (selectedFrames.isEmpty) {
      return const AiResponse(
        provider: 'openrouter_no_frames',
        text:
            'I could not find a good camera frame to analyze. Please try again.',
      );
    }

    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final response = await client.post(
        _endpoint,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://smart-vision-assistant.local',
          'X-Title': 'Smart Vision Assistant',
        },
        body: jsonEncode({
          'model': AppConfig.openRouterModel,
          'provider': {
            'data_collection': 'deny',
            'zdr': true,
          },
          'max_tokens': 250,
          'temperature': 0.2,
          'messages': [
            {
              'role': 'system',
              'content':
                  _promptSecurityService.buildSystemPrompt(intent: intent),
            },
            {
              'role': 'user',
              'content': await _buildUserContent(
                userCommand: userCommand,
                intent: intent,
                selectedFrames: selectedFrames,
                allFrames: allFrames,
                knownFaceName: knownFaceName,
              ),
            },
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AiResponse(
          provider: 'openrouter_error_${response.statusCode}',
          text:
              'The OpenRouter request failed with status ${response.statusCode}. Please try again.',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      final firstChoice = choices?.isNotEmpty == true
          ? choices!.first as Map<String, dynamic>
          : null;
      final message = firstChoice?['message'] as Map<String, dynamic>?;
      final content = message?['content'];
      final text = _extractText(content);

      return AiResponse(
        provider: 'openrouter:${AppConfig.openRouterModel}',
        text: text.isEmpty
            ? 'The model returned an empty response. Please try again.'
            : text,
      );
    } catch (_) {
      return const AiResponse(
        provider: 'openrouter_exception',
        text: 'OpenRouter failed. Please try again.',
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Future<List<Map<String, Object>>> _buildUserContent({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
    String? knownFaceName,
  }) async {
    final content = <Map<String, Object>>[
      {
        'type': 'text',
        'text': _buildPromptText(
          userCommand: userCommand,
          intent: intent,
          selectedFrames: selectedFrames,
          allFrames: allFrames,
          knownFaceName: knownFaceName,
        ),
      },
    ];

    for (final frame in selectedFrames) {
      final bytes = await frame.readBytes();
      content.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
        },
      });
    }

    return content;
  }

  String _buildPromptText({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
    String? knownFaceName,
  }) {
    final buffer = StringBuffer()
      ..writeln(_promptSecurityService.buildUserContextPrompt(
        userCommand: userCommand,
        intent: intent,
      ))
      ..writeln(
        'Captured ${allFrames.length} frames and selected '
        '${selectedFrames.length} keyframes.',
      );

    final faceContext = _buildFaceContext(knownFaceName);
    if (faceContext != null) {
      buffer
        ..writeln()
        ..writeln(faceContext);
    }

    if (intent == VisionIntent.currencyRecognition) {
      buffer
        ..writeln()
        ..writeln('Currency recognition mode is active.')
        ..writeln(
          'A local Egyptian currency YOLOv8 model has been added to the '
          'project for this task: ${EgyptianCurrencyModel.pytorchAssetPath}.',
        )
        ..writeln(
          'Supported banknote values: '
          '${EgyptianCurrencyModel.classes.map((item) => item.valueEgp).toSet().join(', ')} EGP.',
        )
        ..writeln(
          'Inspect the selected keyframes for Egyptian banknotes. If visible, '
          'state each detected value and the estimated total. If uncertain, '
          'say that the currency is not clear and ask the user to hold it '
          'closer or flatter.',
        );
    }

    buffer.writeln('Answer in 1 to 3 short sentences for a blind user.');
    return buffer.toString();
  }

  String? _buildFaceContext(String? knownFaceName) {
    final name = knownFaceName?.trim();
    if (name == null || name.isEmpty) {
      return null;
    }
    if (name.toLowerCase() == 'unknown person') {
      return 'Local face recognition did not match a saved person. Refer to them as an unknown person if relevant.';
    }
    return 'Known face detected locally: $name. Use this identity in your answer if relevant.';
  }

  String _extractText(Object? content) {
    if (content is String) {
      return content.trim();
    }
    if (content is List) {
      return content
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n')
          .trim();
    }
    return '';
  }
}

extension on FrameMetadata {
  Future<List<int>> readBytes() {
    return File(filePath).readAsBytes();
  }
}
