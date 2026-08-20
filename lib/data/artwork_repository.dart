import 'dart:typed_data';

import 'package:lovable_little_artist/local_artist_store.dart';

/// Small repository that exposes lazy access to artwork image bytes when
/// backed by [LocalArtistStore]. Falls back to `null` when the underlying
/// store cannot provide file access.
class ArtworkRepository {
  ArtworkRepository(this.store);

  final ArtistStore store;

  /// Attempts to read the artwork bytes for [fileName]. Returns `null` when
  /// the file is missing or the store doesn't support file access.
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
}
