import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  Completer<String>? _activeCompleter;
  String _activeBestWords = '';
  bool _manualStopRequested = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    final microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      return false;
    }

    final speechStatus = await Permission.speech.status;
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
    bool completeOnFinalResult = true,
    Duration listenFor = const Duration(seconds: 8),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final completer = Completer<String>();
    var bestWords = '';
    _activeCompleter = completer;
    _activeBestWords = '';
    _manualStopRequested = false;

    Future<void> startListening() async {
      if (completer.isCompleted || _speech.isListening) {
        return;
      }

      await _speech.listen(
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(partialResults: true),
        onResult: (SpeechRecognitionResult result) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            bestWords = words;
            _activeBestWords = words;
          }
          onPartialResult?.call(bestWords);

          if (completeOnFinalResult &&
              result.finalResult &&
              !completer.isCompleted) {
            completer.complete(bestWords);
          }
        },
      );
    }

    await startListening();

    final subscriptionTimer =
        Timer.periodic(const Duration(milliseconds: 250), (_) async {
      final status = _speech.isListening ? 'listening' : 'not_listening';
      onStatus?.call(status);

      if (!_speech.isListening && !completer.isCompleted) {
        if (completeOnFinalResult || _manualStopRequested) {
          completer.complete(bestWords);
        } else {
          await startListening();
        }
      }
    });

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => bestWords,
      );
    } finally {
      subscriptionTimer.cancel();
      if (_speech.isListening) {
        await _speech.stop();
      }
      if (identical(_activeCompleter, completer)) {
        _activeCompleter = null;
        _activeBestWords = '';
        _manualStopRequested = false;
      }
    }
  }

  Future<void> stop() async {
    _manualStopRequested = true;
    final completer = _activeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(_activeBestWords);
    }
    await _speech.stop();
  }
}
