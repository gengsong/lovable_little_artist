import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StudioAudio {
  StudioAudio();

  final FlutterTts _tts = FlutterTts();
  bool soundEnabled = true;

  Future<void> initialize({
    required bool sound,
    required String languageCode,
  }) async {
    soundEnabled = sound;
    try {
      await setLanguage(languageCode);
      await _tts.setSpeechRate(.42);
      await _tts.setPitch(1.08);
    } catch (_) {
      // Tests and unsupported platforms may not register the audio plugins.
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      await _tts.setLanguage(languageCode == 'zh' ? 'zh-CN' : 'en-US');
    } catch (_) {
      // Voice prompts stay optional when a system voice is unavailable.
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    if (!enabled) {
      try {
        await _tts.stop();
      } catch (_) {
        // Keep the setting usable when text-to-speech is unavailable.
      }
    }
  }

  Future<void> speak(String text) async {
    if (!soundEnabled) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Voice prompts are optional and must not block a lesson.
    }
  }

  Future<void> success(String message) async {
    if (!soundEnabled) return;
    await SystemSound.play(SystemSoundType.click);
    await speak(message);
  }

  Future<void> tap() async {
    if (soundEnabled) await SystemSound.play(SystemSoundType.click);
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Plugins may already be detached while the app is shutting down.
    }
  }
}
