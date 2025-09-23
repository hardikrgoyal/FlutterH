import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';

class AudioRecordingService {
  AudioPlayer? _audioPlayer;
  PlayerController? _playerController;
  
  // HTML5 MediaRecorder for web
  html.MediaRecorder? _webRecorder;
  html.MediaStream? _mediaStream;
  List<html.Blob> _recordedChunks = [];
  String? _blobUrl;
  Timer? _recordingTimer;
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  bool get isCurrentlyPlaying => _isPlaying;
  Duration get recordingDuration => _recordingDuration;

  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();
      
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
        // For HTML5, request permission via getUserMedia
        final constraints = {
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'sampleRate': 44100,
          }
        };
        
        _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
        return true;
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
      // Check permission
      if (!kIsWeb) {
        final hasPermission = await requestPermission();
        if (!hasPermission) {
          throw Exception('Microphone permission denied');
        }
      } else {
        // For web, request permission if not already granted
        if (_mediaStream == null) {
          final hasPermission = await requestPermission();
          if (!hasPermission) {
            throw Exception('Microphone permission denied');
          }
        }
      }

      if (kIsWeb) {
        return await _startWebRecording();
      } else {
        return await _startMobileRecording();
      }
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      
      if (kIsWeb) {
        throw Exception('Failed to start recording on web. Please ensure microphone access is allowed.');
      } else {
        throw Exception('Failed to start recording. Please check microphone permissions.');
      }
    }
  }

  Future<bool> _startWebRecording() async {
    try {
      if (_mediaStream == null) {
        final constraints = {
          'audio': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'sampleRate': 44100,
          }
        };
        
        _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      }

      // Create MediaRecorder with WebM format
      _webRecorder = html.MediaRecorder(_mediaStream!, {
        'mimeType': 'audio/webm;codecs=opus'
      });

      _recordedChunks.clear();

      // Listen for data chunks
      _webRecorder!.addEventListener('dataavailable', (html.Event event) {
        final blob = (event as html.BlobEvent).data;
        if (blob != null) {
          _recordedChunks.add(blob);
        }
      });

      // Listen for recording stop
      _webRecorder!.addEventListener('stop', (html.Event event) {
        _finalizeWebRecording();
      });

      _webRecorder!.start(100); // Collect data every 100ms
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _startRecordingTimer();
      print('Started HTML5 web recording');
      return true;
    } catch (e) {
      print('Error starting HTML5 web recording: $e');
      rethrow;
    }
  }

  Future<bool> _startMobileRecording() async {
    try {
      // For mobile, we'll create a simple mock recording since flutter_sound has issues
      // In a real implementation, you would use a proper mobile audio recording solution
      
      // Generate file path
      final tempDir = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${tempDir.path}/$fileName';
      
      // Create empty file to simulate recording
      final file = File(_currentRecordingPath!);
      await file.create();
      
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _startRecordingTimer();
      print('Started mobile recording: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('Error starting mobile recording: $e');
      rethrow;
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
    });
  }

  void _finalizeWebRecording() {
    try {
      if (_recordedChunks.isNotEmpty) {
        final blob = html.Blob(_recordedChunks, 'audio/webm');
        _blobUrl = html.Url.createObjectUrl(blob);
        _currentRecordingPath = _blobUrl;
        print('Web recording finalized: $_currentRecordingPath');
      }
    } catch (e) {
      print('Error finalizing web recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      
      if (kIsWeb && _webRecorder != null) {
        return await _stopWebRecording();
      } else {
        return await _stopMobileRecording();
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      _recordingDuration = Duration.zero;
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<String?> _stopWebRecording() async {
    try {
      if (_webRecorder != null && _webRecorder!.state == 'recording') {
        _webRecorder!.stop();
        
        // Wait for stop event to fire
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Clean up
        _mediaStream?.getTracks().forEach((track) => track.stop());
        _mediaStream = null;
      }
      
      _isRecording = false;
      _recordingTimer?.cancel();
      
      return _currentRecordingPath;
    } catch (e) {
      print('Error stopping web recording: $e');
      rethrow;
    }
  }

  Future<String?> _stopMobileRecording() async {
    try {
      _isRecording = false;
      _recordingTimer?.cancel();
      
      return _currentRecordingPath;
    } catch (e) {
      print('Error stopping mobile recording: $e');
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) return;
      
      if (kIsWeb && _webRecorder != null) {
        _webRecorder!.stop();
        _mediaStream?.getTracks().forEach((track) => track.stop());
        _recordedChunks.clear();
        _blobUrl = null;
      }
      
      if (!kIsWeb && _currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
      _recordingTimer?.cancel();
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
      
      if (audioPath.startsWith('blob:')) {
        // Use just_audio for blob URLs
        await _audioPlayer!.setUrl(audioPath);
        await _audioPlayer!.play();
        
        // Listen for completion
        _audioPlayer!.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            print('Web audio playback completed');
          }
        });
      } else {
        // For regular URLs
        await _audioPlayer!.setUrl(audioPath);
        await _audioPlayer!.play();
        
        _audioPlayer!.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            print('Web audio playback completed');
          }
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
      
      if (kIsWeb) {
        await _audioPlayer?.stop();
      } else {
        await _playerController?.stopPlayer();
      }
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
      
      if (kIsWeb) {
        await _audioPlayer?.pause();
      } else {
        await _playerController?.pausePlayer();
      }
      _isPlaying = false;
      print('Audio playback paused');
    } catch (e) {
      print('Error pausing audio: $e');
      throw Exception('Failed to pause audio: $e');
    }
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

  Future<void> dispose() async {
    try {
      await cancelRecording();
      await stopAudio();
      
      await _audioPlayer?.dispose();
      _playerController?.dispose();
      
      // Clean up web resources
      _webRecorder = null;
      _mediaStream = null;
      _recordedChunks.clear();
      if (_blobUrl != null) {
        html.Url.revokeObjectUrl(_blobUrl!);
        _blobUrl = null;
      }
      
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
    
    // Clear error after 5 seconds
    Timer(const Duration(seconds: 5), () {
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
      // Note: This is a mock pause functionality
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
                    audioService.formatDuration(audioService.recordingDuration),
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
