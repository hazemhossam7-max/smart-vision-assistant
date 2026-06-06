import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';
import '../currency/egyptian_currency_model.dart';
import '../vision/frame_metadata.dart';
import '../voice/intent_classifier.dart';
import 'ai_service.dart';

class OpenRouterService implements AiService {
  const OpenRouterService({
    http.Client? client,
  }) : _client = client;

  final http.Client? _client;

  static final Uri _endpoint = Uri.parse(
    'https://openrouter.ai/api/v1/chat/completions',
  );

  @override
  Future<AiResponse> analyzeKeyframes({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
  }) async {
    final apiKey = AppConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      return AiResponse(
        provider: 'openrouter_no_key',
        text:
            'OpenRouter is selected, but no API key was provided. Run the app with OPENROUTER_API_KEY.',
      );
    }

    if (selectedFrames.isEmpty) {
      return const AiResponse(
        provider: 'openrouter_no_frames',
        text: 'I could not find a good camera frame to analyze. Please try again.',
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
          'max_tokens': 250,
          'temperature': 0.2,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a concise visual assistant for blind users. '
                  'Describe important objects, text, obstacles, and spatial layout. '
                  'Give practical safety guidance when relevant. Do not mention frame scores.',
            },
            {
              'role': 'user',
              'content': await _buildUserContent(
                userCommand: userCommand,
                intent: intent,
                selectedFrames: selectedFrames,
                allFrames: allFrames,
              ),
            },
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AiResponse(
          provider: 'openrouter_error_${response.statusCode}',
          text:
              'The OpenRouter request failed with status ${response.statusCode}. ${response.body}',
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
    } catch (error) {
      return AiResponse(
        provider: 'openrouter_exception',
        text: 'OpenRouter failed: $error',
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
  }) async {
    final content = <Map<String, Object>>[
      {
        'type': 'text',
        'text': _buildPromptText(
          userCommand: userCommand,
          intent: intent,
          selectedFrames: selectedFrames,
          allFrames: allFrames,
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
  }) {
    final buffer = StringBuffer()
      ..writeln('User command: "$userCommand"')
      ..writeln('Detected intent: ${intent.label}')
      ..writeln(
        'Captured ${allFrames.length} frames and selected '
        '${selectedFrames.length} keyframes.',
      );

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
