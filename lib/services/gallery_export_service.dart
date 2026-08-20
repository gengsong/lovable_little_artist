import 'dart:typed_data';

import 'package:gal/gal.dart';

class GalleryExportService {
  const GalleryExportService._();

  static const albumName = 'Little Art Studio';

  static Future<void> savePng(Uint8List bytes, {required String name}) async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    final granted = hasAccess || await Gal.requestAccess(toAlbum: true);
    if (!granted) {
      throw Exception('Gallery permission denied');
    }
    await Gal.putImageBytes(bytes, album: albumName, name: name);
  }
}
