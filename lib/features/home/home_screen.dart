import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/security/ai_safety_moderation_service.dart';
import '../../core/security/local_auth_service.dart';
import '../../core/security/privacy_guard_service.dart';
import '../../core/security/security_settings_service.dart';
import '../../core/security/temporary_frame_cleanup_service.dart';
import '../../core/services/logger_service.dart';
import '../ai/ai_service.dart';
import '../ai/ai_service_factory.dart';
import '../camera/camera_service.dart';
import '../camera/frame_capture_service.dart';
import '../security/security_settings_screen.dart';
import '../tts/tts_service.dart';
import '../vision/frame_metadata.dart';
import '../vision/frame_quality_analyzer.dart';
import '../vision/keyframe_selector.dart';
import '../voice/intent_classifier.dart';
import '../voice/voice_service.dart';
import 'widgets/accessible_microphone_button.dart';
import 'widgets/frame_score_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _logger = const LoggerService();
  final _cameraService = CameraService();
  final _voiceService = VoiceService();
  final _intentClassifier = IntentClassifier();
  final _frameAnalyzer = FrameQualityAnalyzer();
  final _keyframeSelector = const KeyframeSelector();
  final _ttsService = TtsService();
  final _privacyGuardService = const PrivacyGuardService();
  final _safetyModerationService = const AiSafetyModerationService();
  final _securitySettingsService = const SecuritySettingsService();
  final _temporaryFrameCleanupService = const TemporaryFrameCleanupService();
  final _localAuthService = LocalAuthService();
  final AiService _aiService = AiServiceFactory.create();

  late final FrameCaptureService _frameCaptureService;

  bool _cameraReady = false;
  bool _voiceReady = false;
  bool _isBusy = false;
  String _status = 'Initializing camera and voice services...';
  String _recognizedCommand = '';
  VisionIntent? _intent;
  String _assistantResponse = '';
  List<FrameMetadata> _allFrames = const [];
  List<FrameMetadata> _selectedFrames = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _frameCaptureService = FrameCaptureService(_cameraService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeServices();
      }
    });
  }

  Future<void> _initializeServices() async {
    try {
      final cameraReady = await _cameraService.initialize();
      final voiceReady = await _voiceService.initialize();
      await _ttsService.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _cameraReady = cameraReady;
        _voiceReady = voiceReady;
        _status = cameraReady && voiceReady
            ? 'Ready. Press the microphone and speak a command.'
            : 'Some permissions are missing. Please allow camera and microphone access.';
      });
    } catch (error) {
      _logger.info('Initialization failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Initialization failed: $error';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeServices();
    }
  }

  Future<void> _handleVoiceCommand() async {
    if (!_cameraReady || !_voiceReady || _isBusy) {
      return;
    }

    var analyzedFrames = <FrameMetadata>[];

    setState(() {
      _isBusy = true;
      _recognizedCommand = '';
      _intent = null;
      _assistantResponse = '';
      _allFrames = const [];
      _selectedFrames = const [];
      _status = 'Listening...';
    });

    try {
      // 1) Record the spoken command and convert it to text.
      final command = await _voiceService.listenForCommand(
        onPartialResult: (text) {
          if (!mounted) {
            return;
          }
          setState(() => _recognizedCommand = text);
        },
      );

      if (command.trim().isEmpty) {
        await _ttsService.speak('I did not hear a command. Please try again.');
        setState(() {
          _status = 'No command recognized. Try again.';
          _isBusy = false;
        });
        return;
      }

      final moderation = _safetyModerationService.moderateUserCommand(command);
      if (!moderation.allowed) {
        await _ttsService.speak(moderation.message);
        if (!mounted) {
          return;
        }
        setState(() {
          _recognizedCommand = command;
          _status = moderation.message;
          _isBusy = false;
        });
        return;
      }

      // 2) Classify the NLP intent before camera processing.
      final intent = _intentClassifier.classify(command);
      setState(() {
        _recognizedCommand = command;
        _intent = intent;
        _status = 'Capturing multiple frames...';
      });

      // 3) Capture a burst, not a single image, so retrieval has choices.
      final rawFrames = await _frameCaptureService.captureBurst(
        duration: const Duration(milliseconds: AppConfig.captureDurationMs),
        fps: AppConfig.captureFps,
      );

      // 4) Score every frame locally using computer vision features.
      setState(() => _status = 'Analyzing frame quality and uniqueness...');
      analyzedFrames = await _analyzeFrames(rawFrames, intent);

      // 5) Remove weak frames and keep only the top keyframes.
      final selectedFrames = _keyframeSelector.selectTopFrames(
        frames: analyzedFrames,
        topK: AppConfig.topKeyframes,
      );
      final safeFrames = _privacyGuardService.filterSafeKeyframes(selectedFrames);

      if (safeFrames.isEmpty) {
        const message = 'I could not find a safe clear frame to analyze. Please try again.';
        await _ttsService.speak(message);
        if (!mounted) {
          return;
        }
        setState(() {
          _allFrames = analyzedFrames;
          _selectedFrames = const [];
          _assistantResponse = '';
          _status = message;
          _isBusy = false;
        });
        return;
      }

      if (AppConfig.productionBuild && AppConfig.requireImageRedaction) {
        const message = 'Image redaction is required for this build before cloud analysis.';
        await _ttsService.speak(message);
        if (!mounted) {
          return;
        }
        setState(() {
          _allFrames = analyzedFrames;
          _selectedFrames = const [];
          _assistantResponse = '';
          _status = message;
          _isBusy = false;
        });
        return;
      }

      final hasConsent = await _ensureCloudConsent(intent);
      if (!hasConsent) {
        await _ttsService.speak('Cloud analysis cancelled.');
        if (!mounted) {
          return;
        }
        setState(() {
          _allFrames = analyzedFrames;
          _selectedFrames = safeFrames;
          _status = 'Cloud analysis cancelled.';
          _isBusy = false;
        });
        return;
      }

      setState(() {
        _allFrames = analyzedFrames;
        _selectedFrames = safeFrames;
        _status = safeFrames.length == selectedFrames.length
            ? 'Sending selected keyframes to secure backend...'
            : 'Sending ${safeFrames.length} privacy-safe keyframes to secure backend...';
      });

      // 6) Send only privacy-safe keyframes plus metadata to the AI layer.
      final response = await _aiService.analyzeKeyframes(
        userCommand: command,
        intent: intent,
        selectedFrames: safeFrames,
        allFrames: analyzedFrames,
      );
      final moderatedResponse =
          _safetyModerationService.moderateAssistantResponse(response.text);

      // 7) Speak the final answer for accessibility.
      await _ttsService.speak(moderatedResponse);

      if (!mounted) {
        return;
      }

      setState(() {
        _assistantResponse = moderatedResponse;
        _status = 'Done. ${safeFrames.length} privacy-safe keyframes selected.';
        _isBusy = false;
      });
    } catch (error) {
      _logger.info('Pipeline failed: $error');
      await _ttsService.speak(
          'Sorry, something went wrong while processing the camera frames.');

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Pipeline failed: $error';
        _isBusy = false;
      });
    } finally {
      final cleanupFrames = await _securitySettingsService.isPrivacyModeEnabled();
      if (cleanupFrames && analyzedFrames.isNotEmpty) {
        await _temporaryFrameCleanupService.deleteTemporaryFrameFiles(analyzedFrames);
      }
    }
  }

  Future<bool> _ensureCloudConsent(VisionIntent intent) async {
    if (await _securitySettingsService.hasCloudConsent()) {
      return true;
    }

    final warning = _privacyGuardService.buildPrivacyWarningForIntent(intent);
    await _ttsService.speak(warning);

    if (!mounted) {
      return false;
    }

    final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Cloud AI Consent'),
              content: Text(
                '$warning\n\nThis will send selected camera frames to the AI for analysis. Do you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (accepted) {
      await _securitySettingsService.setCloudConsentGiven(true);
    }

    return accepted;
  }

  Future<List<FrameMetadata>> _analyzeFrames(
    List<XFile> rawFrames,
    VisionIntent intent,
  ) async {
    final analyzedFrames = <FrameMetadata>[];
    FrameMetadata? previousFrame;

    for (var index = 0; index < rawFrames.length; index++) {
      final metadata = await _frameAnalyzer.analyzeFrame(
        frameFile: rawFrames[index],
        index: index,
        intent: intent,
        previousFrame: previousFrame,
      );
      analyzedFrames.add(metadata);
      previousFrame = metadata;
    }

    return analyzedFrames;
  }

  Future<void> _openSecuritySettings() async {
    if (await _securitySettingsService.isBiometricLockEnabled()) {
      final authenticated = await _localAuthService.authenticateForSensitiveAction(
        reason: 'Authenticate to open Security and Privacy settings.',
      );
      if (!authenticated) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SecuritySettingsScreen(knownFrames: _allFrames),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceService.stop();
    _ttsService.stop();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Vision Assistant'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isBusy ? null : _openSecuritySettings,
            child: const Text('Security & Privacy'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CameraPreviewPanel(
              controller: controller,
              cameraReady: _cameraReady,
            ),
            const SizedBox(height: 24),
            Center(
              child: AccessibleMicrophoneButton(
                isBusy: _isBusy,
                onPressed: _handleVoiceCommand,
              ),
            ),
            const SizedBox(height: 20),
            _InfoPanel(
              status: _status,
              command: _recognizedCommand,
              intent: _intent,
              response: _assistantResponse,
              selectedFrames: _selectedFrames,
            ),
            if (_allFrames.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Frame Analysis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ..._allFrames.map((frame) => FrameScoreTile(frame: frame)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewPanel extends StatelessWidget {
  const _CameraPreviewPanel({
    required this.controller,
    required this.cameraReady,
  });

  final CameraController? controller;
  final bool cameraReady;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: cameraReady && activeController != null
              ? CameraPreview(activeController)
              : const Center(
                  child: Text(
                    'Camera preview unavailable',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.status,
    required this.command,
    required this.intent,
    required this.response,
    required this.selectedFrames,
  });

  final String status;
  final String command;
  final VisionIntent? intent;
  final String response;
  final List<FrameMetadata> selectedFrames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(status),
              if (command.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Command', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(command),
              ],
              if (intent != null) ...[
                const SizedBox(height: 12),
                Text('Intent', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(intent!.label),
              ],
              if (selectedFrames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Selected Keyframes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  selectedFrames
                      .map((frame) =>
                          '#${frame.index + 1}: ${frame.finalScore.toStringAsFixed(2)}')
                      .join('  '),
                ),
              ],
              if (response.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Assistant Response', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(response),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
