import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/studio_localizations.dart';

void main() {
  test('all static Chinese interface strings have English translations', () {
    final source = File('lib/main.dart').readAsStringSync();
    final chinese = RegExp(r'[\u3400-\u9fff]');
    final strings = RegExp(r"'([^'\n]*[\u3400-\u9fff][^'\n]*)'")
        .allMatches(source)
        .map((match) => match.group(1)!)
        .where((value) => !value.contains(r'$'))
        .toSet();
    final missing =
        strings
            .where(
              (value) => chinese.hasMatch(
                StudioLocalizations.translate(value, const Locale('en')),
              ),
            )
            .where((value) => value != '简体中文')
            .toList()
          ..sort();

    expect(missing, isEmpty, reason: 'Missing English translations: $missing');
  });
}
