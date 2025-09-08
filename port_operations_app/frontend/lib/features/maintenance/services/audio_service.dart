import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AudioService {
  final ImagePicker _picker = ImagePicker();
  
  /// Record audio note (placeholder - uses image picker for now)
  /// In future, replace with actual audio recording library
  Future<File?> recordAudioNote() async {
    try {
      // For now, we'll use image picker as a placeholder
      // In a real implementation, you would use an audio recording package
      final XFile? audioFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (audioFile != null) {
        return File(audioFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to record audio: $e');
    }
  }
  
  /// Pick existing audio file from device
  Future<File?> pickAudioFile() async {
    try {
      // Note: ImagePicker doesn't support audio files directly
      // This is a placeholder implementation
      // In a real app, you would use file_picker package for audio files
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      
      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick audio file: $e');
    }
  }
  
  /// Show audio recording dialog
  Future<File?> showAudioRecordingDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Audio Note'),
        content: const Text('Choose an option for adding audio note:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final file = await pickAudioFile();
              if (context.mounted && file != null) {
                Navigator.pop(context, file);
              }
            },
            child: const Text('Choose File'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final file = await recordAudioNote();
              if (context.mounted && file != null) {
                Navigator.pop(context, file);
              }
            },
            child: const Text('Record Now'),
          ),
        ],
      ),
    );
  }
  
  /// Get audio file duration (placeholder)
  Future<Duration?> getAudioDuration(File audioFile) async {
    try {
      // Placeholder implementation
      // In a real app, you would use audio metadata libraries
      return const Duration(seconds: 30);
    } catch (e) {
      return null;
    }
  }
  
  /// Format audio duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  
  /// Save audio file to app directory
  Future<String> saveAudioFile(File audioFile, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio_notes');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final extension = path.extension(audioFile.path);
      final newPath = '${audioDir.path}/$fileName$extension';
      final savedFile = await audioFile.copy(newPath);
      
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save audio file: $e');
    }
  }
  
  /// Delete audio file
  Future<void> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete audio file: $e');
    }
  }
  
  /// Check if audio file exists
  Future<bool> audioFileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}

// Audio player service for playback
class AudioPlayerService {
  /// Play audio file (placeholder)
  Future<void> playAudio(String audioPath) async {
    try {
      // Placeholder implementation
      // In a real app, you would use audio player packages like audioplayers
      print('🎵 Playing audio: $audioPath');
      // await audioPlayer.play(DeviceFileSource(audioPath));
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }
  
  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      // Placeholder implementation
      print('⏹️ Stopping audio playback');
      // await audioPlayer.stop();
    } catch (e) {
      throw Exception('Failed to stop audio: $e');
    }
  }
  
  /// Pause audio playback
  Future<void> pauseAudio() async {
    try {
      // Placeholder implementation
      print('⏸️ Pausing audio playback');
      // await audioPlayer.pause();
    } catch (e) {
      throw Exception('Failed to pause audio: $e');
    }
  }
}

// Riverpod providers
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

// Audio recording state provider
final audioRecordingStateProvider = StateNotifierProvider<AudioRecordingState, AudioRecordingStatus>((ref) {
  return AudioRecordingState();
});

enum AudioRecordingStatus {
  idle,
  recording,
  playing,
  paused,
}

class AudioRecordingState extends StateNotifier<AudioRecordingStatus> {
  AudioRecordingState() : super(AudioRecordingStatus.idle);
  
  void startRecording() {
    state = AudioRecordingStatus.recording;
  }
  
  void stopRecording() {
    state = AudioRecordingStatus.idle;
  }
  
  void startPlaying() {
    state = AudioRecordingStatus.playing;
  }
  
  void pausePlaying() {
    state = AudioRecordingStatus.paused;
  }
  
  void stopPlaying() {
    state = AudioRecordingStatus.idle;
  }
} 