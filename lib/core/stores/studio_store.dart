import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:lovable_little_artist/local_artist_store.dart';
import 'package:lovable_little_artist/studio_audio.dart';

/// A lightweight ChangeNotifier that encapsulates app-level state and
/// delegates persistence to an [ArtistStore]. This is a first-step refactor
/// to move business logic out of large Widget states.
class StudioStore extends ChangeNotifier {
  StudioStore({required this.store, StudioAudio? audio}) : _audio = audio ?? StudioAudio();

  final ArtistStore store;
  final StudioAudio _audio;

  ArtistStoreSnapshot? _snapshot;
  List<StoredArtwork> _artworks = [];
  Map<String, Object?> _preferences = {};

  List<StoredArtwork> get artworks => List.unmodifiable(_artworks);
  Map<String, Object?> get preferences => Map.unmodifiable(_preferences);

  /// Load snapshot from the underlying store into memory.
  Future<void> load() async {
    _snapshot = await store.load();
    _artworks = List.of(_snapshot!.artworks);
    _preferences = Map.of(_snapshot!.preferences);
    notifyListeners();
  }

  Future<void> savePreference(String key, Object? value) async {
    if (value == null) {
      _preferences.remove(key);
    } else {
      _preferences[key] = value;
    }
    notifyListeners();
    try {
      await store.savePreferences(_preferences);
    } catch (_) {
      // Keep UI responsive; callers may surface errors.
    }
  }

  Future<void> addArtwork(StoredArtwork artwork) async {
    _artworks.insert(0, artwork);
    notifyListeners();
    try {
      await store.saveArtwork(artwork);
    } catch (_) {}
  }

  Future<void> updateArtwork(StoredArtwork artwork) async {
    final idx = _artworks.indexWhere((a) => a.id == artwork.id);
    if (idx >= 0) _artworks[idx] = artwork;
    notifyListeners();
    try {
      await store.updateArtwork(artwork);
    } catch (_) {}
  }

  Future<void> deleteArtwork(String id) async {
    _artworks.removeWhere((a) => a.id == id);
    notifyListeners();
    try {
      await store.deleteArtwork(id);
    } catch (_) {}
  }

  Future<Map<String, Object?>?> loadDraft(String key) => store.loadDraft(key);
  Future<void> saveDraft(String key, Map<String, Object?> draft) => store.saveDraft(key, draft);
  Future<void> deleteDraft(String key) => store.deleteDraft(key);

  /// Attempt to read artwork bytes from the underlying store if supported.
  Future<Uint8List?> readArtworkBytes(String fileName) async {
    if (store is LocalArtistStore) {
      try {
        return await (store as LocalArtistStore).readArtworkBytes(fileName);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> initializeAudio({required bool sound, required String languageCode}) => _audio.initialize(sound: sound, languageCode: languageCode);

  Future<void> setSoundEnabled(bool enabled) => _audio.setSoundEnabled(enabled);
}
