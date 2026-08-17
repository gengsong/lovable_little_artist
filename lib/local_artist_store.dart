import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class StoredArtwork {
  const StoredArtwork({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.fileName,
    required this.isFavorite,
    required this.source,
    required this.backgroundColor,
    required this.pngBytes,
    this.lessonId,
    this.replayData,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final String fileName;
  final bool isFavorite;
  final String source;
  final int backgroundColor;
  final Uint8List pngBytes;
  final String? lessonId;
  final Map<String, Object?>? replayData;

  StoredArtwork copyWith({String? title, bool? isFavorite}) => StoredArtwork(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    fileName: fileName,
    isFavorite: isFavorite ?? this.isFavorite,
    source: source,
    backgroundColor: backgroundColor,
    pngBytes: pngBytes,
    lessonId: lessonId,
    replayData: replayData,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'fileName': fileName,
    'isFavorite': isFavorite,
    'source': source,
    'backgroundColor': backgroundColor,
    if (lessonId != null) 'lessonId': lessonId,
    if (replayData != null) 'replayData': replayData,
  };
}

class ArtistStoreSnapshot {
  const ArtistStoreSnapshot({
    required this.artworks,
    required this.lessonProgress,
    required this.nextArtworkNumber,
    required this.preferences,
  });

  final List<StoredArtwork> artworks;
  final Map<String, int> lessonProgress;
  final int nextArtworkNumber;
  final Map<String, Object?> preferences;
}

abstract class ArtistStore {
  Future<ArtistStoreSnapshot> load();
  Future<void> saveArtwork(StoredArtwork artwork);
  Future<void> updateArtwork(StoredArtwork artwork);
  Future<void> deleteArtwork(String id);
  Future<void> saveLessonProgress(Map<String, int> progress);
  Future<void> savePreferences(Map<String, Object?> preferences);
  Future<Map<String, Object?>?> loadDraft(String key);
  Future<void> saveDraft(String key, Map<String, Object?> draft);
  Future<void> deleteDraft(String key);
}

/// Fast, isolated storage used by widget previews and tests.
class MemoryArtistStore implements ArtistStore {
  MemoryArtistStore({Map<String, Object?>? preferences})
    : _preferences =
          preferences ?? {'onboardingComplete': true, 'soundEnabled': false};

  final List<StoredArtwork> _artworks = [];
  final Map<String, int> _lessonProgress = {};
  final Map<String, Map<String, Object?>> _drafts = {};
  int _nextArtworkNumber = 1;
  Map<String, Object?> _preferences;

  @override
  Future<ArtistStoreSnapshot> load() async => ArtistStoreSnapshot(
    artworks: List.unmodifiable(_artworks),
    lessonProgress: Map.unmodifiable(_lessonProgress),
    nextArtworkNumber: _nextArtworkNumber,
    preferences: Map.unmodifiable(_preferences),
  );

  @override
  Future<void> saveArtwork(StoredArtwork artwork) async {
    _artworks.insert(0, artwork);
    _nextArtworkNumber++;
  }

  @override
  Future<void> updateArtwork(StoredArtwork artwork) async {
    final index = _artworks.indexWhere((item) => item.id == artwork.id);
    if (index >= 0) _artworks[index] = artwork;
  }

  @override
  Future<void> deleteArtwork(String id) async {
    _artworks.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> saveLessonProgress(Map<String, int> progress) async {
    _lessonProgress
      ..clear()
      ..addAll(progress);
  }

  @override
  Future<void> savePreferences(Map<String, Object?> preferences) async {
    _preferences = Map.of(preferences);
  }

  @override
  Future<Map<String, Object?>?> loadDraft(String key) async {
    final draft = _drafts[key];
    return draft == null ? null : Map.of(draft);
  }

  @override
  Future<void> saveDraft(String key, Map<String, Object?> draft) async {
    _drafts[key] = Map.of(draft);
  }

  @override
  Future<void> deleteDraft(String key) async {
    _drafts.remove(key);
  }
}

class LocalArtistStore implements ArtistStore {
  LocalArtistStore({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;
  Directory? _root;
  List<StoredArtwork> _artworks = [];
  Map<String, int> _lessonProgress = {};
  int _nextArtworkNumber = 1;
  Map<String, Object?> _preferences = {};
  Future<void> _stateWrites = Future.value();

  Future<Directory?> _ensureRoot() async {
    if (_root != null) return _root;
    try {
      final support = await _directoryProvider();
      final root = Directory('${support.path}/little_artist');
      await Directory('${root.path}/artworks').create(recursive: true);
      await Directory('${root.path}/drafts').create(recursive: true);
      _root = root;
      return root;
    } catch (_) {
      // Widget tests and unsupported platforms may not register path_provider.
      // The in-memory cache still keeps the current session fully functional.
      return null;
    }
  }

  @override
  Future<ArtistStoreSnapshot> load() async {
    final root = await _ensureRoot();
    if (root == null) {
      return ArtistStoreSnapshot(
        artworks: List.unmodifiable(_artworks),
        lessonProgress: Map.unmodifiable(_lessonProgress),
        nextArtworkNumber: _nextArtworkNumber,
        preferences: Map.unmodifiable(_preferences),
      );
    }
    final stateFile = File('${root.path}/state.json');
    if (!await stateFile.exists()) {
      return const ArtistStoreSnapshot(
        artworks: [],
        lessonProgress: {},
        nextArtworkNumber: 1,
        preferences: {},
      );
    }
    try {
      final json =
          jsonDecode(await stateFile.readAsString()) as Map<String, dynamic>;
      final progressJson =
          json['lessonProgress'] as Map<String, dynamic>? ?? const {};
      _lessonProgress = progressJson.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
      _nextArtworkNumber = (json['nextArtworkNumber'] as num?)?.toInt() ?? 1;
      _preferences = (json['preferences'] as Map<String, dynamic>? ?? const {})
          .cast<String, Object?>();
      final loaded = <StoredArtwork>[];
      for (final item in (json['artworks'] as List<dynamic>? ?? const [])) {
        final metadata = item as Map<String, dynamic>;
        final fileName = metadata['fileName'] as String;
        final imageFile = File('${root.path}/artworks/$fileName');
        if (!await imageFile.exists()) continue;
        loaded.add(
          StoredArtwork(
            id: metadata['id'] as String,
            title: metadata['title'] as String,
            createdAt:
                DateTime.tryParse(metadata['createdAt'] as String? ?? '') ??
                DateTime.now(),
            fileName: fileName,
            isFavorite: metadata['isFavorite'] as bool? ?? false,
            source: metadata['source'] as String? ?? 'free',
            backgroundColor:
                (metadata['backgroundColor'] as num?)?.toInt() ?? 0xFFD2F2DC,
            lessonId: metadata['lessonId'] as String?,
            replayData: (metadata['replayData'] as Map<String, dynamic>?)
                ?.cast<String, Object?>(),
            pngBytes: await imageFile.readAsBytes(),
          ),
        );
      }
      _artworks = loaded;
    } catch (_) {
      _artworks = [];
      _lessonProgress = {};
      _nextArtworkNumber = 1;
      _preferences = {};
    }
    return ArtistStoreSnapshot(
      artworks: List.unmodifiable(_artworks),
      lessonProgress: Map.unmodifiable(_lessonProgress),
      nextArtworkNumber: _nextArtworkNumber,
      preferences: Map.unmodifiable(_preferences),
    );
  }

  @override
  Future<void> saveArtwork(StoredArtwork artwork) async {
    _artworks.insert(0, artwork);
    _nextArtworkNumber++;
    final root = await _ensureRoot();
    if (root != null) {
      await File(
        '${root.path}/artworks/${artwork.fileName}',
      ).writeAsBytes(artwork.pngBytes, flush: true);
      await _writeState(root);
    }
  }

  @override
  Future<void> updateArtwork(StoredArtwork artwork) async {
    final index = _artworks.indexWhere((item) => item.id == artwork.id);
    if (index < 0) return;
    _artworks[index] = artwork;
    final root = await _ensureRoot();
    if (root != null) await _writeState(root);
  }

  @override
  Future<void> deleteArtwork(String id) async {
    final index = _artworks.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final removed = _artworks.removeAt(index);
    final root = await _ensureRoot();
    if (root != null) {
      final file = File('${root.path}/artworks/${removed.fileName}');
      if (await file.exists()) await file.delete();
      await _writeState(root);
    }
  }

  @override
  Future<void> saveLessonProgress(Map<String, int> progress) async {
    _lessonProgress = Map.of(progress);
    final root = await _ensureRoot();
    if (root != null) await _writeState(root);
  }

  @override
  Future<void> savePreferences(Map<String, Object?> preferences) async {
    _preferences = Map.of(preferences);
    final root = await _ensureRoot();
    if (root != null) await _writeState(root);
  }

  @override
  Future<Map<String, Object?>?> loadDraft(String key) async {
    final root = await _ensureRoot();
    if (root == null) return null;
    final file = File('${root.path}/drafts/${_safeKey(key)}.json');
    if (!await file.exists()) return null;
    try {
      return (jsonDecode(await file.readAsString()) as Map<String, dynamic>)
          .cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDraft(String key, Map<String, Object?> draft) async {
    final root = await _ensureRoot();
    if (root == null) return;
    await _writeJsonAtomic(
      File('${root.path}/drafts/${_safeKey(key)}.json'),
      draft,
    );
  }

  @override
  Future<void> deleteDraft(String key) async {
    final root = await _ensureRoot();
    if (root == null) return;
    final file = File('${root.path}/drafts/${_safeKey(key)}.json');
    if (await file.exists()) await file.delete();
  }

  Future<void> _writeState(Directory root) {
    final operation = _stateWrites.then(
      (_) => _writeJsonAtomic(File('${root.path}/state.json'), {
        'version': 1,
        'nextArtworkNumber': _nextArtworkNumber,
        'lessonProgress': _lessonProgress,
        'preferences': _preferences,
        'artworks': _artworks.map((item) => item.toJson()).toList(),
      }),
    );
    _stateWrites = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _writeJsonAtomic(File file, Object value) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(value), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  String _safeKey(String key) => key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
