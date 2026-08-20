import 'dart:typed_data';
import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

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

  static Future<String> saveStoryFile(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/story_exports');
    await directory.create(recursive: true);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
