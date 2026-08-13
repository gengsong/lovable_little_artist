import 'package:flutter_test/flutter_test.dart';
import 'package:lovable_little_artist/main.dart';

void main() {
  testWidgets('shows Lovable-inspired home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LittleArtistVerseApp());

    expect(find.text('米娅!'), findsOneWidget);
    expect(find.text('今天想做什么？'), findsOneWidget);
    expect(find.text('自由画画'), findsOneWidget);
    expect(find.text('跟着学画'), findsOneWidget);
    expect(find.text('最近画的'), findsOneWidget);
  });
}
