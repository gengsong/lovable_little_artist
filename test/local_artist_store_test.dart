import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/local_artist_store.dart';

void main() {
  test('local store restores artworks, lesson progress, and drafts', () async {
    final directory = await Directory.systemTemp.createTemp(
      'little_artist_store_test_',
    );
    addTearDown(() async => directory.delete(recursive: true));
    Future<Directory> directoryProvider() async => directory;

    final firstStore = LocalArtistStore(directoryProvider: directoryProvider);
    final artwork = StoredArtwork(
      id: 'drawing-1',
      title: '彩虹花园',
      createdAt: DateTime.utc(2026, 8, 17),
      fileName: 'drawing-1.png',
      isFavorite: true,
      source: 'free',
      backgroundColor: 0xFFD2F2DC,
      pngBytes: Uint8List.fromList([1, 2, 3, 4]),
    );
    await firstStore.saveArtwork(artwork);
    await firstStore.saveLessonProgress({'round-cat': 3});
    await firstStore.saveDraft('free-drawing', {
      'version': 1,
      'strokes': <Object?>[],
    });

    final restoredStore = LocalArtistStore(
      directoryProvider: directoryProvider,
    );
    final snapshot = await restoredStore.load();

    expect(snapshot.artworks, hasLength(1));
    expect(snapshot.artworks.single.title, '彩虹花园');
    expect(snapshot.artworks.single.pngBytes, [1, 2, 3, 4]);
    expect(snapshot.lessonProgress['round-cat'], 3);
    expect(snapshot.nextArtworkNumber, 2);
    expect(await restoredStore.loadDraft('free-drawing'), isNotNull);

    await restoredStore.deleteArtwork('drawing-1');
    await restoredStore.deleteDraft('free-drawing');
    final emptyStore = LocalArtistStore(directoryProvider: directoryProvider);
    expect((await emptyStore.load()).artworks, isEmpty);
    expect(await emptyStore.loadDraft('free-drawing'), isNull);
  });
}
