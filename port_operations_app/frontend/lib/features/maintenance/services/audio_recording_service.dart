import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Conditional imports for web compatibility
import 'dart:io' if (dart.library.html) 'dart:html' as platform;
import 'package:path_provider/path_provider.dart' if (dart.library.html) 'package:flutter/services.dart';

class AudioRecordingService {
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // For web, we'll use a simpler approach
      if (kIsWeb) {
        print('Audio service initialized for web platform');
      } else {
        // Mobile initialization would go here
        print('Audio service initialized for mobile platform');
      }
    } catch (e) {
      print('Error initializing audio service: $e');
      throw Exception('Failed to initialize audio service: $e');
    }
  }

  /// Request microphone permission with web compatibility
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) {
        // For web, we'll simulate permission request
        // In a real implementation, you'd use the web audio APIs
        return true;
      } else {
        // Mobile permission handling would go here
        return true;
      }
    } catch (e) {
      print('Error requesting microphone permission: $e');
      throw Exception('Failed to request microphone permission: $e');
    }
  }

  /// Start recording audio with web compatibility
  Future<bool> startRecording() async {
    try {
      if (kIsWeb) {
        // For web, we'll simulate recording
        // In production, you'd implement MediaRecorder API
        print('Starting web audio recording simulation');
        _isRecording = true;
        _currentRecordingPath = 'web_recording_${DateTime.now().millisecondsSinceEpoch}';
        return true;
      } else {
        // Mobile recording implementation would go here
        _isRecording = true;
        return true;
      }
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        _isRecording = false;
        
        if (kIsWeb) {
          // For web, return the simulated path
          return _currentRecordingPath;
        } else {
          // Mobile stop recording would go here
          return _currentRecordingPath;
        }
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      throw Exception('Failed to stop recording: $e');
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        _isRecording = false;
        _currentRecordingPath = null;
        print('Recording cancelled');
      }
    } catch (e) {
      print('Error cancelling recording: $e');
      throw Exception('Failed to cancel recording: $e');
    }
  }

  /// Play audio file with web compatibility
  Future<void> playAudio(String audioPath) async {
    try {
      if (kIsWeb) {
        // For web, simulate audio playback
        print('Playing audio on web: $audioPath');
        _isPlaying = true;
        
        // Simulate playback duration
        Timer(const Duration(seconds: 2), () {
          _isPlaying = false;
        });
      } else {
        // Mobile playback would go here
        _isPlaying = true;
      }
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      if (_isPlaying) {
        _isPlaying = false;
        print('Audio playback stopped');
      }
    } catch (e) {
      print('Error stopping audio: $e');
      throw Exception('Failed to stop audio: $e');
    }
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    try {
      if (_isPlaying) {
        _isPlaying = false;
        print('Audio playback paused');
      }
    } catch (e) {
      print('Error pausing audio: $e');
      throw Exception('Failed to pause audio: $e');
    }
  }

  /// Get audio duration with fallback
  Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      // Return a default duration for web compatibility
      return const Duration(seconds: 10);
    } catch (e) {
      print('Error getting audio duration: $e');
      return const Duration(seconds: 10);
    }
  }

  /// Format duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${twoDigits(seconds)}';
  }

  /// Clean up temporary files (web-safe)
  Future<void> cleanupTempFiles() async {
    try {
      if (kIsWeb) {
        print('Cleaning up web audio resources');
      } else {
        // Mobile cleanup would go here
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      if (_isPlaying) {
        await stopAudio();
      }
      await cleanupTempFiles();
      print('Audio service disposed');
    } catch (e) {
      print('Error disposing audio service: $e');
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

/// Enhanced Audio Recording Widget with web compatibility
class AudioRecordingWidget extends ConsumerStatefulWidget {
  final Function(String audioPath) onAudioRecorded;
  final VoidCallback? onCancel;
  final String? initialAudioPath;

  const AudioRecordingWidget({
    super.key,
    required this.onAudioRecorded,
    this.onCancel,
    this.initialAudioPath,
  });

  @override
  ConsumerState<AudioRecordingWidget> createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends ConsumerState<AudioRecordingWidget>
    with TickerProviderStateMixin {
  Timer? _durationTimer;
  Duration _recordingDuration = Duration.zero;
  String? _errorMessage;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Initialize with existing audio if provided
    if (widget.initialAudioPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(audioRecordingStateProvider.notifier).stopRecording(widget.initialAudioPath);
      });
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      }
    });
    _pulseController.repeat(reverse: true);
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _pulseController.stop();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    
    // Clear error after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final audioService = ref.read(audioRecordingServiceProvider);
      
      // Show web-specific message
      if (kIsWeb) {
        _showError('Audio recording is simulated on web platform');
      }
      
      final success = await audioService.startRecording();
      
      if (success) {
        ref.read(audioRecordingStateProvider.notifier).startRecording();
        _startTimer();
      } else {
        _showError('Failed to start recording');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final audioService = ref.read(audioRecordingServiceProvider);
      final audioPath = await audioService.stopRecording();
      
      ref.read(audioRecordingStateProvider.notifier).stopRecording(audioPath);
      _stopTimer();
      
      if (audioPath != null) {
        widget.onAudioRecorded(audioPath);
      } else {
        _showError('Recording failed - no audio captured');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  Future<void> _cancelRecording() async {
    try {
      final audioService = ref.read(audioRecordingServiceProvider);
      await audioService.cancelRecording();
      ref.read(audioRecordingStateProvider.notifier).cancelRecording();
      _stopTimer();
      setState(() {
        _recordingDuration = Duration.zero;
        _errorMessage = null;
      });
      widget.onCancel?.call();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _playAudio(String audioPath) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final audioService = ref.read(audioRecordingServiceProvider);
      await audioService.playAudio(audioPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb 
                ? 'Audio playback simulated on web' 
                : 'Playing audio...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioRecordingStateProvider);
    final audioService = ref.read(audioRecordingServiceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Web platform notice
          if (kIsWeb) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Audio recording is simulated on web platform',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!audioState.isRecording && audioState.audioPath == null) ...[
            // Initial state - show record button
            Column(
              children: [
                Icon(
                  Icons.mic,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb 
                      ? 'Tap to simulate recording an audio note'
                      : 'Tap to record an audio note',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startRecording,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mic),
                    label: Text(_isLoading ? 'Starting...' : 'Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (audioState.isRecording) ...[
            // Recording state
            Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  kIsWeb ? 'Simulating Recording...' : 'Recording...',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  audioService.formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _cancelRecording,
                        icon: const Icon(Icons.close, color: Colors.red),
                        iconSize: 28,
                        tooltip: 'Cancel Recording',
                      ),
                    ),
                    // Stop button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _stopRecording,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.stop, color: Colors.green),
                        iconSize: 28,
                        tooltip: 'Stop Recording',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else if (audioState.audioPath != null) ...[
            // Recorded state - show audio with play/delete options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kIsWeb 
                              ? 'Audio recording simulated successfully'
                              : 'Audio recorded successfully',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Play button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading 
                              ? null 
                              : () => _playAudio(audioState.audioPath!),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isLoading ? 'Loading...' : 'Play'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(audioRecordingStateProvider.notifier).reset();
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
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