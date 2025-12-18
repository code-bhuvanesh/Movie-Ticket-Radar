import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticket_radar/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TicketRadarApp()));

    // Verify that the app title is displayed
    expect(find.text('Ticket Radar'), findsOneWidget);
  });
}
