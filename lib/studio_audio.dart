import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class StudioAudio {
  StudioAudio();

  AudioPlayer? _musicPlayer;
  final FlutterTts _tts = FlutterTts();
  bool soundEnabled = true;
  bool musicEnabled = true;
  String? _musicPath;

  Future<void> initialize({required bool sound, required bool music}) async {
    soundEnabled = sound;
    musicEnabled = music;
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(.42);
      await _tts.setPitch(1.08);
    } catch (_) {
      // Tests and unsupported platforms may not register the audio plugins.
    }
    if (musicEnabled) await _startMusic();
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

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
    if (enabled) {
      await _startMusic();
    } else {
      try {
        await _musicPlayer?.stop();
      } catch (_) {
        // Keep the setting usable when audio playback is unavailable.
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

  Future<void> success() async {
    if (!soundEnabled) return;
    await SystemSound.play(SystemSoundType.click);
    await speak('太棒啦，完成得真好！');
  }

  Future<void> tap() async {
    if (soundEnabled) await SystemSound.play(SystemSoundType.click);
  }

  Future<void> _startMusic() async {
    try {
      final player = _musicPlayer ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      _musicPath ??= await _createMusicFile();
      await player.play(DeviceFileSource(_musicPath!), volume: .12);
    } catch (_) {
      // Audio is an enhancement; drawing remains available if playback fails.
    }
  }

  Future<String> _createMusicFile() async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/little_artist_music.wav');
    if (!await file.exists()) {
      await file.writeAsBytes(_buildMusicWav(), flush: true);
    }
    return file.path;
  }

  Uint8List _buildMusicWav() {
    const sampleRate = 22050;
    const seconds = 8;
    const channels = 1;
    const bitsPerSample = 16;
    const notes = [
      261.63,
      329.63,
      392.00,
      523.25,
      392.00,
      329.63,
      293.66,
      349.23,
    ];
    final sampleCount = sampleRate * seconds;
    final dataLength = sampleCount * 2;
    final bytes = ByteData(44 + dataLength);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, channels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(
      28,
      sampleRate * channels * bitsPerSample ~/ 8,
      Endian.little,
    );
    bytes.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final time = i / sampleRate;
      final beat = (time / .5).floor();
      final withinBeat = (time % .5) / .5;
      final envelope = math.sin(math.pi * withinBeat).clamp(0.0, 1.0);
      final frequency = notes[beat % notes.length];
      final tone = math.sin(2 * math.pi * frequency * time);
      final harmony = math.sin(2 * math.pi * frequency / 2 * time) * .35;
      final sample = ((tone + harmony) * envelope * 2800).round().clamp(
        -32768,
        32767,
      );
      bytes.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
      await _musicPlayer?.dispose();
    } catch (_) {
      // Plugins may already be detached while the app is shutting down.
    }
  }
}
