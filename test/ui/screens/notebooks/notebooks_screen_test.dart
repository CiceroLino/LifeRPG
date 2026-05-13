import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/notebook.dart';
import 'package:liferpg/l10n/app_localizations.dart';
import 'package:liferpg/providers/notebook_provider.dart';
import 'package:liferpg/ui/screens/notebooks/notebooks_screen.dart';

class FakeNotebookProvider extends NotebookProvider {
  FakeNotebookProvider(this.fakeNotebooks);

  final List<Notebook> fakeNotebooks;

  @override
  List<Notebook> get filteredNotebooks => fakeNotebooks;

  @override
  List<Notebook> get notebooks => fakeNotebooks;

  @override
  Map<int, int> get noteCountsByNotebook => {
    for (final notebook in fakeNotebooks)
      if (notebook.id != null) notebook.id!: 2,
  };

  @override
  bool get isLoading => false;

  @override
  Future<void> loadNotebooks() async {}
}

void main() {
  testWidgets('shows notebook empty state and add action', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<NotebookProvider>.value(
        value: FakeNotebookProvider(const []),
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: NotebooksScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No notebooks yet'), findsOneWidget);
    expect(find.byTooltip('New notebook'), findsOneWidget);
  });

  testWidgets('renders notebook cards with note counts', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<NotebookProvider>.value(
        value: FakeNotebookProvider([
          Notebook(id: 1, name: 'Field Journal', description: 'Routes'),
        ]),
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: NotebooksScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Field Journal'), findsOneWidget);
    expect(find.text('Routes'), findsOneWidget);
    expect(find.text('2 notes'), findsOneWidget);
  });
}
