import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/tome.dart';
import 'package:liferpg/l10n/app_localizations.dart';
import 'package:liferpg/providers/tome_provider.dart';
import 'package:liferpg/ui/screens/tomes/tomes_screen.dart';

class FakeTomeProvider extends TomeProvider {
  FakeTomeProvider(this.fakeTomes);

  final List<Tome> fakeTomes;

  @override
  List<Tome> get filteredTomes => fakeTomes;

  @override
  List<Tome> get tomes => fakeTomes;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadTomes() async {}
}

void main() {
  testWidgets('shows tome empty state and import action', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TomeProvider>.value(
        value: FakeTomeProvider(const []),
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TomesScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No tomes yet'), findsOneWidget);
    expect(find.byTooltip('Import tome'), findsOneWidget);
  });

  testWidgets('renders tome cards with progress', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TomeProvider>.value(
        value: FakeTomeProvider([
          Tome(
            id: 1,
            title: 'Arcane PDF',
            author: 'Archivist',
            filePath: '/tmp/arcane.pdf',
            currentPage: 25,
            totalPages: 100,
          ),
        ]),
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TomesScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Arcane PDF'), findsOneWidget);
    expect(find.text('Archivist'), findsOneWidget);
    expect(find.text('Page 25 of 100 · 25%'), findsOneWidget);
  });
}
