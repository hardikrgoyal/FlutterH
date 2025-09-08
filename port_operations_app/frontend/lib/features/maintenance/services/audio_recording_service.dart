import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecordingService {
  RecorderController? _recorderController;
  PlayerController? _playerController;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the service
  Future<void> initialize() async {
    _recorderController = RecorderController();
    _playerController = PlayerController();
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return false;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      if (_recorderController == null) {
        await initialize();
      }

      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio_notes');

      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = 'audio_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${audioDir.path}/$fileName';

      await _recorderController!.record(path: filePath);

      _isRecording = true;
      _currentRecordingPath = filePath;
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (_isRecording && _recorderController != null) {
        final path = await _recorderController!.stop();
        _isRecording = false;
        return path;
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording && _recorderController != null) {
        await _recorderController!.stop();
        _isRecording = false;

        // Delete the cancelled recording file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      print('Error cancelling recording: $e');
    }
  }

  /// Play audio file
  Future<void> playAudio(String audioPath) async {
    try {
      if (_playerController == null) {
        await initialize();
      }
      
      await _playerController!.preparePlayer(
        path: audioPath,
      );
      await _playerController!.startPlayer();
      _isPlaying = true;
    } catch (e) {
      print('Error playing audio: $e');
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      if (_playerController != null) {
        await _playerController!.stopPlayer();
        _isPlaying = false;
      }
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    try {
      if (_playerController != null) {
        await _playerController!.pausePlayer();
        _isPlaying = false;
      }
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  /// Get audio duration
  Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      if (_playerController == null) {
        await initialize();
      }
      await _playerController!.preparePlayer(path: audioPath);
      final durationInMs = _playerController!.maxDuration;
      return Duration(milliseconds: durationInMs);
    } catch (e) {
      print('Error getting audio duration: $e');
      return const Duration(seconds: 10); // fallback
    }
  }

  /// Format duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${twoDigits(seconds)}';
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_recorderController != null) {
      _recorderController!.dispose();
      _recorderController = null;
    }
    if (_playerController != null) {
      _playerController!.dispose();
      _playerController = null;
    }
  }
}

// Riverpod providers
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Audio recording state provider
final audioRecordingStateProvider = StateNotifierProvider<AudioRecordingStateNotifier, AudioRecordingState>((ref) {
  return AudioRecordingStateNotifier();
});

class AudioRecordingState {
  final bool isRecording;
  final bool isPlaying;
  final Duration recordingDuration;
  final String? audioPath;

  const AudioRecordingState({
    this.isRecording = false,
    this.isPlaying = false,
    this.recordingDuration = Duration.zero,
    this.audioPath,
  });

  AudioRecordingState copyWith({
    bool? isRecording,
    bool? isPlaying,
    Duration? recordingDuration,
    String? audioPath,
  }) {
    return AudioRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}

class AudioRecordingStateNotifier extends StateNotifier<AudioRecordingState> {
  AudioRecordingStateNotifier() : super(const AudioRecordingState());

  void startRecording() {
    state = state.copyWith(isRecording: true, recordingDuration: Duration.zero);
  }

  void stopRecording(String? audioPath) {
    state = state.copyWith(isRecording: false, audioPath: audioPath);
  }

  void cancelRecording() {
    state = state.copyWith(isRecording: false, audioPath: null, recordingDuration: Duration.zero);
  }

  void updateDuration(Duration duration) {
    state = state.copyWith(recordingDuration: duration);
  }

  void startPlaying() {
    state = state.copyWith(isPlaying: true);
  }

  void stopPlaying() {
    state = state.copyWith(isPlaying: false);
  }

  void reset() {
    state = const AudioRecordingState();
  }
}

/// WhatsApp-like Audio Recording Widget
class AudioRecordingWidget extends ConsumerStatefulWidget {
  final Function(String audioPath) onAudioRecorded;
  final VoidCallback? onCancel;

  const AudioRecordingWidget({
    super.key,
    required this.onAudioRecorded,
    this.onCancel,
  });

  @override
  ConsumerState<AudioRecordingWidget> createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends ConsumerState<AudioRecordingWidget> {
  Timer? _durationTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioRecordingStateProvider);
    final audioService = ref.read(audioRecordingServiceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          if (!audioState.isRecording && audioState.audioPath == null) ...[
            // Initial state - show record button
            const Text(
              'Tap to record an audio note',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final success = await audioService.startRecording();
                if (success) {
                  ref.read(audioRecordingStateProvider.notifier).startRecording();
                  _startTimer();
                }
              },
              icon: const Icon(Icons.mic),
              label: const Text('Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ] else if (audioState.isRecording) ...[
            // Recording state
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  audioService.formatDuration(_recordingDuration),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                IconButton(
                  onPressed: () async {
                    await audioService.cancelRecording();
                    ref.read(audioRecordingStateProvider.notifier).cancelRecording();
                    _stopTimer();
                    setState(() {
                      _recordingDuration = Duration.zero;
                    });
                    widget.onCancel?.call();
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  iconSize: 32,
                ),
                // Stop button
                IconButton(
                  onPressed: () async {
                    final audioPath = await audioService.stopRecording();
                    ref.read(audioRecordingStateProvider.notifier).stopRecording(audioPath);
                    _stopTimer();
                    if (audioPath != null) {
                      widget.onAudioRecorded(audioPath);
                    }
                  },
                  icon: const Icon(Icons.stop, color: Colors.green),
                  iconSize: 32,
                ),
              ],
            ),
          ] else if (audioState.audioPath != null) ...[
            // Recorded state - show audio with play/delete options
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audiotrack, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Audio recorded successfully',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await audioService.playAudio(audioState.audioPath!);
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.blue),
                    tooltip: 'Play',
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(audioRecordingStateProvider.notifier).reset();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 