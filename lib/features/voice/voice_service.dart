import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    final microphoneStatus = await Permission.microphone.request();
    if (!microphoneStatus.isGranted) {
      return false;
    }

    final speechStatus = await Permission.speech.request();
    if (!speechStatus.isGranted && !speechStatus.isLimited) {
      return false;
    }

    return _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
  }

  Future<String> listenForCommand({
    void Function(String text)? onPartialResult,
    void Function(String status)? onStatus,
  }) async {
    final completer = Completer<String>();
    var bestWords = '';

    await _speech.listen(
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (SpeechRecognitionResult result) {
        bestWords = result.recognizedWords.trim();
        onPartialResult?.call(bestWords);

        if (result.finalResult && !completer.isCompleted) {
          completer.complete(bestWords);
        }
      },
    );

    final subscriptionTimer =
        Timer.periodic(const Duration(milliseconds: 250), (_) {
      final status = _speech.isListening ? 'listening' : 'not_listening';
      onStatus?.call(status);

      if (!_speech.isListening && !completer.isCompleted) {
        completer.complete(bestWords);
      }
    });

    try {
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => bestWords,
      );
    } finally {
      subscriptionTimer.cancel();
      if (_speech.isListening) {
        await _speech.stop();
      }
    }
  }

  Future<void> stop() => _speech.stop();
}
