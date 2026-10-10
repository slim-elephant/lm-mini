import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/l10n/app_localizations.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/providers/chat_provider.dart';
import 'package:lm_mini/providers/settings_provider.dart';
import 'package:lm_mini/providers/theme_provider.dart';
import 'package:lm_mini/widgets/message_bubble.dart';
import 'package:provider/provider.dart';

Widget _host(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

final _msg = ChatMessage(
  id: 'u1',
  content: 'hello',
  role: 'user',
  timestamp: DateTime(2026, 10, 11, 9, 30),
);

void main() {
  testWidgets('failed user bubble shows error icon + retry line; tap retries',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(_host(MessageBubble(
      message: _msg,
      isFailed: true,
      onRetry: () => retries++,
    )));
    await tester.pump();

    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    expect(find.text('Not delivered · Tap to retry'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Message not delivered. Tap to retry.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Not delivered · Tap to retry'));
    await tester.tap(find.byIcon(Icons.error_rounded));
    expect(retries, 2);
  });

  testWidgets('retrying shows progress instead of the error', (tester) async {
    await tester.pumpWidget(_host(MessageBubble(
      message: _msg,
      isFailed: true,
      isRetrying: true,
      onRetry: () {},
    )));
    await tester.pump();
    expect(find.byIcon(Icons.error_rounded), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sending…'), findsOneWidget);
  });

  testWidgets('delivered user bubble has no failure UI', (tester) async {
    await tester.pumpWidget(_host(MessageBubble(message: _msg)));
    await tester.pump();
    expect(find.byIcon(Icons.error_rounded), findsNothing);
    expect(find.text('Not delivered · Tap to retry'), findsNothing);
  });
}
