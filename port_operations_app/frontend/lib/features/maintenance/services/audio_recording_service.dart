import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  PlayerController? _playerController;
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  bool get isCurrentlyPlaying => _isPlaying;

  Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        _playerController = PlayerController();
      }
      print('Audio service initialized successfully');
    } catch (e) {
      print('Error initializing audio service: $e');
      throw Exception('Failed to initialize audio service: $e');
    }
  }

  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) {
        // Use record package permission check
        try {
          final hasPermission = await _recorder.hasPermission();
          print('Web microphone permission status: $hasPermission');
          return hasPermission;
        } catch (e) {
          print('Error checking web microphone permission: $e');
          // Return true to let the browser handle permission prompt
          return true;
        }
      } else {
        final status = await Permission.microphone.request();
        return status == PermissionStatus.granted;
      }
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  Future<bool> startRecording() async {
    try {
      // Check permission for both web and mobile
      final hasPermission = await requestPermission();
      if (!hasPermission && !kIsWeb) {
        throw Exception('Microphone permission denied');
      }

      // Generate file path
      if (kIsWeb) {
        _currentRecordingPath = 'recording_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _currentRecordingPath = '${tempDir.path}/$fileName';
      }

      // Start recording with platform-specific configuration
      if (kIsWeb) {
        // Try different web recording configurations
        try {
          print('Attempting web recording with WAV format...');
          await _recorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 44100,
              bitRate: 128000,
            ),
            path: _currentRecordingPath!,
          );
        } catch (e) {
          print('WAV recording failed, trying PCM16: $e');
          await _recorder.start(
            const RecordConfig(
              encoder: AudioEncoder.pcm16bits,
              sampleRate: 44100,
            ),
            path: _currentRecordingPath!,
          );
        }
      } else {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
          ),
          path: _currentRecordingPath!,
        );
      }
      
      _isRecording = true;
      print('Started recording: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      
      if (kIsWeb) {
        throw Exception(_getWebPermissionErrorMessage(e.toString()));
      } else {
        throw Exception('Failed to start recording. Please check microphone permissions.');
      }
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      
      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null) {
        _currentRecordingPath = path;
        
        // Debug: Check if we actually have audio data on web
        if (kIsWeb && path.startsWith('blob:')) {
          print('Web recording blob URL: $path');
          await _debugWebBlob(path);
        }
      }
      
      print('Stopped recording: $path');
      return path ?? _currentRecordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      throw Exception('Failed to stop recording: $e');
    }
  }
  
  Future<void> _debugWebBlob(String blobUrl) async {
    if (kIsWeb) {
      try {
        final response = await html.HttpRequest.request(blobUrl, responseType: 'blob');
        final blob = response.response as html.Blob;
        print('Blob size: ${blob.size} bytes');
        print('Blob type: ${blob.type}');
        
        if (blob.size == 0) {
          print('⚠️ WARNING: Blob is empty - no audio data recorded!');
        } else {
          print('✅ Blob contains ${blob.size} bytes of audio data');
        }
      } catch (e) {
        print('Error debugging blob: $e');
      }
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) return;
      
      await _recorder.stop();
      
      if (!kIsWeb && _currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _isRecording = false;
      _currentRecordingPath = null;
      print('Recording cancelled');
    } catch (e) {
      print('Error cancelling recording: $e');
      throw Exception('Failed to cancel recording: $e');
    }
  }

  Future<void> playAudio(String audioPath) async {
    try {
      if (kIsWeb) {
        await _playWebAudio(audioPath);
      } else {
        await _playMobileAudio(audioPath);
      }
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
      throw Exception('Failed to play audio: $e');
    }
  }

  Future<void> _playWebAudio(String audioPath) async {
    try {
      _isPlaying = true;
      print('Playing web audio: $audioPath');
      
      if (kIsWeb) {
        // Debug: Check if blob still exists and has data
        if (audioPath.startsWith('blob:')) {
          await _debugWebBlob(audioPath);
        }
        
        // Use HTML5 Audio API for web playback
        final audio = html.AudioElement();
        audio.src = audioPath;
        audio.preload = 'auto';
        audio.volume = 1.0; // Set volume to maximum
        audio.controls = true; // Add controls for debugging
        
        // Add event listeners
        audio.onEnded.listen((_) {
          _isPlaying = false;
          print('Web audio playback completed');
        });
        
        audio.onError.listen((event) {
          _isPlaying = false;
          print('Web audio playback error: $event');
        });
        
        // Add load event listener to check duration
        audio.addEventListener('loadedmetadata', (event) {
          print('Audio metadata loaded, duration: ${audio.duration} seconds');
          print('Audio volume: ${audio.volume}');
          print('Audio muted: ${audio.muted}');
        });
        
        audio.addEventListener('canplay', (event) {
          print('Audio can start playing');
        });
        
        audio.addEventListener('volumechange', (event) {
          print('Audio volume changed to: ${audio.volume}');
        });
        
        // Temporarily add audio element to DOM for debugging
        audio.style.position = 'fixed';
        audio.style.top = '10px';
        audio.style.right = '10px';
        audio.style.zIndex = '9999';
        html.document.body!.append(audio);
        
        // Remove after playback completes
        audio.onEnded.listen((_) {
          Timer(const Duration(seconds: 1), () {
            audio.remove();
          });
        });
        
        // Start playback
        try {
          await audio.play();
          print('Audio play() called successfully');
        } catch (e) {
          print('Error calling audio.play(): $e');
          audio.remove(); // Remove on error too
          _isPlaying = false;
          rethrow;
        }
      } else {
        // Fallback for non-web platforms
        Timer(const Duration(seconds: 3), () {
          _isPlaying = false;
        });
      }
      
    } catch (e) {
      _isPlaying = false;
      print('Error playing web audio: $e');
      rethrow;
    }
  }

  Future<void> _playMobileAudio(String audioPath) async {
    try {
      if (_playerController == null) {
        _playerController = PlayerController();
      }
      
      _isPlaying = true;
      
      String playPath = audioPath;
      if (!audioPath.startsWith('/') && !audioPath.startsWith('http')) {
        if (audioPath.contains('maintenance_audio')) {
          playPath = 'http://127.0.0.1:8000/media/$audioPath';
        }
      }
      
      await _playerController!.preparePlayer(
        path: playPath,
        shouldExtractWaveform: false,
      );
      
      await _playerController!.startPlayer();
      
      // Listen for completion
      _playerController!.onCompletion.listen((_) {
        _isPlaying = false;
      });
      
      print('Playing mobile audio: $playPath');
    } catch (e) {
      _isPlaying = false;
      print('Error playing mobile audio: $e');
      rethrow;
    }
  }

  Future<void> stopAudio() async {
    try {
      if (!_isPlaying) return;
      
      await _playerController?.stopPlayer();
      _isPlaying = false;
      print('Audio playback stopped');
    } catch (e) {
      print('Error stopping audio: $e');
      throw Exception('Failed to stop audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      if (!_isPlaying) return;
      
      await _playerController?.pausePlayer();
      _isPlaying = false;
      print('Audio playback paused');
    } catch (e) {
      print('Error pausing audio: $e');
      throw Exception('Failed to pause audio: $e');
    }
  }

  Duration getRecordingDuration() {
    return Duration.zero;
  }

  List<double> getWaveformData() {
    return [];
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getWebPermissionErrorMessage(String error) {
    if (error.contains('AbortError')) {
      return 'Microphone permission was cancelled. Please click the microphone icon in your browser\'s address bar and allow access, then try again.';
    } else if (error.contains('NotAllowedError')) {
      return 'Microphone access was denied. Please check your browser settings:\n1. Click the lock/microphone icon in the address bar\n2. Set microphone to "Allow"\n3. Refresh the page and try again.';
    } else if (error.contains('NotFoundError')) {
      return 'No microphone found. Please ensure a microphone is connected and try again.';
    } else if (error.contains('NotReadableError')) {
      return 'Microphone is already in use by another application. Please close other apps using the microphone and try again.';
    } else {
      return 'Recording failed on web. Please ensure you\'re using HTTPS and allow microphone access.';
    }
  }

  Future<void> dispose() async {
    try {
      await cancelRecording();
      await stopAudio();
      
      await _recorder.dispose();
      _playerController?.dispose();
      
      print('Audio service disposed');
    } catch (e) {
      print('Error disposing audio service: $e');
    }
  }
}

// Provider for the audio recording service
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

// Audio recording state provider
final audioRecordingStateProvider = StateNotifierProvider<AudioRecordingStateNotifier, AudioRecordingState>((ref) {
  return AudioRecordingStateNotifier();
});

class AudioRecordingState {
  final bool isRecording;
  final String? audioPath;
  final Duration recordingDuration;

  const AudioRecordingState({
    this.isRecording = false,
    this.audioPath,
    this.recordingDuration = Duration.zero,
  });

  AudioRecordingState copyWith({
    bool? isRecording,
    String? audioPath,
    Duration? recordingDuration,
  }) {
    return AudioRecordingState(
      isRecording: isRecording ?? this.isRecording,
      audioPath: audioPath ?? this.audioPath,
      recordingDuration: recordingDuration ?? this.recordingDuration,
    );
  }
}

class AudioRecordingStateNotifier extends StateNotifier<AudioRecordingState> {
  AudioRecordingStateNotifier() : super(const AudioRecordingState());

  void startRecording() {
    state = state.copyWith(isRecording: true, audioPath: null);
  }

  void updateDuration(Duration duration) {
    state = state.copyWith(recordingDuration: duration);
  }

  void stopRecording(String? audioPath) {
    state = state.copyWith(isRecording: false, audioPath: audioPath, recordingDuration: Duration.zero);
  }

  void cancelRecording() {
    state = state.copyWith(isRecording: false, audioPath: null, recordingDuration: Duration.zero);
  }

  void reset() {
    state = const AudioRecordingState();
  }
}

/// Enhanced Audio Recording Widget with WhatsApp-like UX
class AudioRecordingWidget extends ConsumerStatefulWidget {
  final Function(String audioPath) onAudioRecorded;
  final VoidCallback? onCancel;
  final String? initialAudioPath;

  const AudioRecordingWidget({
    Key? key,
    required this.onAudioRecorded,
    this.onCancel,
    this.initialAudioPath,
  }) : super(key: key);

  @override
  ConsumerState<AudioRecordingWidget> createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends ConsumerState<AudioRecordingWidget>
    with TickerProviderStateMixin {
  
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPlayingAudio = false;
  bool _isPaused = false;
  
  late AnimationController _pulseAnimation;
  late AnimationController _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseAnimation = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Set initial state if we have an audio path
    if (widget.initialAudioPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(audioRecordingStateProvider.notifier).stopRecording(widget.initialAudioPath);
      });
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseAnimation.dispose();
    _waveAnimation.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
      ref.read(audioRecordingStateProvider.notifier).updateDuration(_recordingDuration);
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
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
        _pulseAnimation.repeat(reverse: true);
        _waveAnimation.repeat(reverse: true);
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
      _pulseAnimation.stop();
      _waveAnimation.stop();
      
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

  Future<void> _pauseRecording() async {
    try {
      final audioService = ref.read(audioRecordingServiceProvider);
      // Note: flutter_sound doesn't support pause/resume, so we'll simulate it
      setState(() {
        _isPaused = true;
      });
      _stopTimer();
      _pulseAnimation.stop();
      _waveAnimation.stop();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _resumeRecording() async {
    try {
      setState(() {
        _isPaused = false;
      });
      _startTimer();
      _pulseAnimation.repeat(reverse: true);
      _waveAnimation.repeat(reverse: true);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _cancelRecording() async {
    try {
      final audioService = ref.read(audioRecordingServiceProvider);
      await audioService.cancelRecording();
      ref.read(audioRecordingStateProvider.notifier).cancelRecording();
      _stopTimer();
      _pulseAnimation.stop();
      _waveAnimation.stop();
      setState(() {
        _recordingDuration = Duration.zero;
        _errorMessage = null;
        _isPaused = false;
      });
      widget.onCancel?.call();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _playAudio(String audioPath) async {
    if (_isPlayingAudio) {
      // Stop current playback
      try {
        final audioService = ref.read(audioRecordingServiceProvider);
        await audioService.stopAudio();
        setState(() {
          _isPlayingAudio = false;
        });
      } catch (e) {
        _showError('Error stopping audio: ${e.toString().replaceAll('Exception: ', '')}');
      }
      return;
    }

    setState(() {
      _isPlayingAudio = true;
    });

    try {
      final audioService = ref.read(audioRecordingServiceProvider);
      await audioService.playAudio(audioPath);
      
      // Monitor playback state
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        final isStillPlaying = audioService.isCurrentlyPlaying;
        if (!isStillPlaying && _isPlayingAudio) {
          setState(() {
            _isPlayingAudio = false;
          });
          timer.cancel();
        }
      });
      
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() {
        _isPlayingAudio = false;
      });
    }
  }

  Widget _buildWaveformBars() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final height = 4.0 + (20.0 * _waveAnimation.value * (index % 2 == 0 ? 1 : 0.5));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioRecordingStateProvider);
    final audioService = ref.read(audioRecordingServiceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (!audioState.isRecording && audioState.audioPath == null) ...[
            // Initial state - WhatsApp-like mic button
            GestureDetector(
              onTap: _isLoading ? null : _startRecording,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey[300] : const Color(0xFF25D366), // WhatsApp green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isLoading 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to record voice message',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ] else if (audioState.isRecording) ...[
            // Recording state - Classic recording interface
            Column(
              children: [
                // Recording indicator with waveform
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // Recording dot and waveform
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Recording dot
                          if (!_isPaused) ...[
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.7 + (0.3 * _pulseAnimation.value)),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          // Waveform animation or paused indicator
                          if (!_isPaused) 
                            _buildWaveformBars()
                          else
                            Row(
                              children: [
                                const Icon(Icons.pause, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Recording Paused',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Duration
                      Text(
                        audioService.formatDuration(_recordingDuration),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.red,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        _isPaused ? 'Tap resume to continue' : 'Recording in progress...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    GestureDetector(
                      onTap: _cancelRecording,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 28,
                        ),
                      ),
                    ),
                    
                    // Pause/Resume button
                    GestureDetector(
                      onTap: _isPaused ? _resumeRecording : _pauseRecording,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isPaused ? const Color(0xFF25D366) : Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    
                    // Stop button
                    GestureDetector(
                      onTap: _isLoading ? null : _stopRecording,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey[300] : Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 28,
                            ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Button labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _isPaused ? 'Resume' : 'Pause',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Stop',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else if (audioState.audioPath != null) ...[
            // Recorded state - WhatsApp-like audio message bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF8C6), // WhatsApp message bubble color
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: () => _playAudio(audioState.audioPath!),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isPlayingAudio ? Colors.grey[400] : const Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Waveform visualization (static for now)
                  Expanded(
                    child: Container(
                      height: 24,
                      child: Row(
                        children: List.generate(20, (index) {
                          final heights = [8.0, 12.0, 6.0, 16.0, 10.0, 14.0, 8.0, 18.0, 12.0, 6.0,
                                         10.0, 14.0, 8.0, 12.0, 16.0, 6.0, 10.0, 8.0, 14.0, 12.0];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            width: 2,
                            height: heights[index % heights.length],
                            decoration: BoxDecoration(
                              color: _isPlayingAudio && index < 8 
                                ? const Color(0xFF25D366) 
                                : Colors.grey[400],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Duration
                  Text(
                    '0:03', // You can make this dynamic based on actual audio duration
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Delete button
                  GestureDetector(
                    onTap: () {
                      ref.read(audioRecordingStateProvider.notifier).reset();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
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