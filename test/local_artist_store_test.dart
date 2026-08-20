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
      replayData: {
        'canvasWidth': 700,
        'canvasHeight': 500,
        'strokes': <Object?>[],
      },
    );
    await firstStore.saveArtwork(artwork);
    await firstStore.saveLessonProgress({'round-cat': 3});
    await firstStore.savePreferences({
      'onboardingComplete': true,
      'soundEnabled': false,
      'ageGroup': '6-8岁',
    });
    await firstStore.saveDraft('free-drawing', {
      'version': 1,
      'strokes': <Object?>[],
    });
    await firstStore.saveDraft('animation-theater-project', {
      'version': 1,
      'id': 'theater-1',
      'storyId': 'space-pet',
      'artworkId': 'drawing-1',
      'activeActIndex': 1,
      'acts': [
        {
          'background': 'space',
          'points': [
            {'milliseconds': 0, 'x': .5, 'y': .56},
            {'milliseconds': 800, 'x': .8, 'y': .32},
          ],
          'cues': [
            {'milliseconds': 400, 'action': 'fly'},
          ],
        },
      ],
    });

    final restoredStore = LocalArtistStore(
      directoryProvider: directoryProvider,
    );
    final snapshot = await restoredStore.load();

    expect(snapshot.artworks, hasLength(1));
    expect(snapshot.artworks.single.title, '彩虹花园');
    expect(snapshot.artworks.single.pngBytes, [1, 2, 3, 4]);
    expect(snapshot.artworks.single.replayData?['canvasWidth'], 700);
    expect(snapshot.lessonProgress['round-cat'], 3);
    expect(snapshot.preferences['soundEnabled'], isFalse);
    expect(snapshot.preferences['ageGroup'], '6-8岁');
    expect(snapshot.nextArtworkNumber, 2);
    expect(await restoredStore.loadDraft('free-drawing'), isNotNull);
    final theaterDraft = await restoredStore.loadDraft(
      'animation-theater-project',
    );
    expect(theaterDraft?['storyId'], 'space-pet');
    expect((theaterDraft?['acts'] as List).single['background'], 'space');

    await restoredStore.deleteArtwork('drawing-1');
    await restoredStore.deleteDraft('free-drawing');
    final emptyStore = LocalArtistStore(directoryProvider: directoryProvider);
    expect((await emptyStore.load()).artworks, isEmpty);
    expect(await emptyStore.loadDraft('free-drawing'), isNull);
  });
}
