import 'package:file_picker/file_picker.dart';
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
  final importedFiles = <PlatformFile>[];

  @override
  List<Tome> get filteredTomes => fakeTomes;

  @override
  List<Tome> get tomes => fakeTomes;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadTomes() async {}

  @override
  Future<int?> importTome(PlatformFile file) async {
    importedFiles.add(file);
    return importedFiles.length;
  }
}

class FakeFilePicker extends FilePicker {
  FakeFilePicker(this.result);

  final FilePickerResult? result;
  bool? pickedWithReadStream;
  FileType? pickedType;
  List<String>? pickedAllowedExtensions;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    pickedType = type;
    pickedAllowedExtensions = allowedExtensions;
    pickedWithReadStream = withReadStream;
    return result;
  }
}

void main() {
  late FilePicker filePickerBaseline;

  setUpAll(() {
    try {
      filePickerBaseline = FilePicker.platform;
    } catch (_) {
      FilePicker.platform = FakeFilePicker(null);
      filePickerBaseline = FilePicker.platform;
    }
  });

  void overrideFilePicker(FilePicker filePicker) {
    final original = FilePicker.platform;
    FilePicker.platform = filePicker;
    addTearDown(() => FilePicker.platform = original);
  }

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

  testWidgets('imports selected PDF through provider with read stream', (
    tester,
  ) async {
    final filePicker = FakeFilePicker(
      FilePickerResult([
        PlatformFile(name: 'manual.pdf', path: '/tmp/manual.pdf', size: 1),
      ]),
    );
    overrideFilePicker(filePicker);
    final provider = FakeTomeProvider(const []);

    await tester.pumpWidget(
      ChangeNotifierProvider<TomeProvider>.value(
        value: provider,
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TomesScreen()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Import tome'));
    await tester.pump();

    expect(filePicker.pickedType, FileType.custom);
    expect(filePicker.pickedAllowedExtensions, ['pdf']);
    expect(filePicker.pickedWithReadStream, isTrue);
    expect(provider.importedFiles.single.name, 'manual.pdf');
  });

  tearDownAll(() {
    FilePicker.platform = filePickerBaseline;
  });
}
