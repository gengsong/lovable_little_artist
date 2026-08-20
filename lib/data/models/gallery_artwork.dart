import 'dart:typed_data';

import 'package:flutter/material.dart';

enum SketchKind { sun, house, cat, rocket }

class GalleryArtwork {
  const GalleryArtwork({
    required this.id,
    required this.title,
    required this.createdLabel,
    required this.color,
    this.kind,
    this.pngBytes,
    this.isFavorite = false,
    this.isUserCreated = false,
    this.createdAt,
    this.source = 'sample',
    this.lessonId,
    this.replayData,
  });

  final String id;
  final String title;
  final String createdLabel;
  final Color color;
  final SketchKind? kind;
  final Uint8List? pngBytes;
  final bool isFavorite;
  final bool isUserCreated;
  final DateTime? createdAt;
  final String source;
  final String? lessonId;
  final Map<String, Object?>? replayData;

  GalleryArtwork copyWith({String? title, bool? isFavorite}) {
    return GalleryArtwork(
      id: id,
      title: title ?? this.title,
      createdLabel: createdLabel,
      color: color,
      kind: kind,
      pngBytes: pngBytes,
      isFavorite: isFavorite ?? this.isFavorite,
      isUserCreated: isUserCreated,
      createdAt: createdAt,
      source: source,
      lessonId: lessonId,
      replayData: replayData,
    );
  }
}

String artworkSourceLabel(GalleryArtwork artwork) {
  if (!artwork.isUserCreated) return '示例作品';
  return switch (artwork.source) {
    'lesson' => '课程作品',
    'coloring' => '涂色作品',
    'challenge' => '挑战作品',
    _ => '自由创作',
  };
}
