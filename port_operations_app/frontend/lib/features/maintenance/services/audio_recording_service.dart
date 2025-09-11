import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

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
    try {
      _recorderController = RecorderController();
      _playerController = PlayerController();
      
      // Add listeners for player state changes
      _playerController?.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
      });
    } catch (e) {
      print('Error initializing audio service: $e');
      throw Exception('Failed to initialize audio service: $e');
    }
  }

  /// Request microphone permission with better error handling
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // Guide user to settings
        throw Exception('Microphone permission permanently denied. Please enable it in app settings.');
      }

      return false;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      throw Exception('Failed to request microphone permission: $e');
    }
  }

  /// Start recording audio with improved error handling
  Future<bool> startRecording() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      if (_recorderController == null) {
        await initialize();
      }

      // Stop any ongoing playback
      if (_isPlaying) {
        await stopAudio();
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
      _isRecording = false;
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Stop recording audio with validation
  Future<String?> stopRecording() async {
    try {
      if (_isRecording && _recorderController != null) {
        final path = await _recorderController!.stop();
        _isRecording = false;
        
        // Validate the recorded file
        if (path != null && await File(path).exists()) {
          final fileSize = await File(path).length();
          if (fileSize > 0) {
            return path;
          } else {
            // Delete empty file
            await File(path).delete();
            throw Exception('Recording failed - empty file');
          }
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
      throw Exception('Failed to cancel recording: $e');
    }
  }

  /// Play audio file (local or remote URL) with better error handling
  Future<void> playAudio(String audioPath) async {
    try {
      if (_playerController == null) {
        await initialize();
      }
      
      // Stop any ongoing recording
      if (_isRecording) {
        await cancelRecording();
      }
      
      String localPath = audioPath;
      
      // If it's a URL, download the file first
      if (audioPath.startsWith('http')) {
        localPath = await _downloadAudioFile(audioPath);
      }
      
      // Validate file exists
      if (!await File(localPath).exists()) {
        throw Exception('Audio file not found');
      }
      
      await _playerController!.preparePlayer(path: localPath);
      await _playerController!.startPlayer();
      _isPlaying = true;
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Download audio file from URL for playback with timeout
  Future<String> _downloadAudioFile(String url) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 60);
      
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/temp_audio');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final fileName = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${audioDir.path}/$fileName';
      
      await dio.download(url, filePath);
      
      // Validate downloaded file
      if (!await File(filePath).exists() || await File(filePath).length() == 0) {
        throw Exception('Downloaded file is invalid');
      }
      
      return filePath;
    } catch (e) {
      print('Error downloading audio file: $e');
      throw Exception('Failed to download audio file: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      if (_playerController != null && _isPlaying) {
        await _playerController!.stopPlayer();
        _isPlaying = false;
      }
    } catch (e) {
      print('Error stopping audio: $e');
      throw Exception('Failed to stop audio: $e');
    }
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    try {
      if (_playerController != null && _isPlaying) {
        await _playerController!.pausePlayer();
        _isPlaying = false;
      }
    } catch (e) {
      print('Error pausing audio: $e');
      throw Exception('Failed to pause audio: $e');
    }
  }

  /// Get audio duration with error handling
  Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      if (_playerController == null) {
        await initialize();
      }
      
      String localPath = audioPath;
      if (audioPath.startsWith('http')) {
        localPath = await _downloadAudioFile(audioPath);
      }
      
      await _playerController!.preparePlayer(path: localPath);
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

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tempAudioDir = Directory('${directory.path}/temp_audio');
      
      if (await tempAudioDir.exists()) {
        final files = tempAudioDir.listSync();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            final age = DateTime.now().difference(stat.modified);
            // Delete files older than 1 hour
            if (age.inHours > 1) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      if (_recorderController != null) {
        if (_isRecording) {
          await _recorderController!.stop();
        }
        _recorderController!.dispose();
        _recorderController = null;
      }
      if (_playerController != null) {
        if (_isPlaying) {
          await _playerController!.stopPlayer();
        }
        _playerController!.dispose();
        _playerController = null;
      }
      
      // Clean up temp files
      await cleanupTempFiles();
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

/// Enhanced Audio Recording Widget with better UX
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
          const SnackBar(
            content: Text('Playing audio...'),
            duration: Duration(seconds: 2),
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
                const Text(
                  'Tap to record an audio note',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
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
                  'Recording...',
                  style: TextStyle(
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
                        decoration: BoxDecoration(
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
                      const Expanded(
                        child: Text(
                          'Audio recorded successfully',
                          style: TextStyle(
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