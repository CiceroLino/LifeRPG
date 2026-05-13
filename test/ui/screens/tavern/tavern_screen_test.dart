import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/l10n/app_localizations.dart';
import 'package:liferpg/providers/tavern_provider.dart';
import 'package:liferpg/services/tavern_audio_service.dart';
import 'package:liferpg/ui/screens/tavern/tavern_screen.dart';

class FakeTavernPlayback implements TavernPlayback {
  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<TavernPlaybackCommand> get commandStream => const Stream.empty();

  @override
  Future<Duration?> load(AudioTrack track) async => track.duration;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}
}

class FakeTavernProvider extends TavernProvider {
  FakeTavernProvider({
    required this.fakeTracks,
    this.fakeActiveTrack,
    this.fakeIsPlaying = false,
    this.fakePosition = Duration.zero,
    this.fakeDuration,
    this.nullImportPaths = const {},
    this.throwImportPaths = const {},
  }) : super(playback: FakeTavernPlayback());

  final List<AudioTrack> fakeTracks;
  final AudioTrack? fakeActiveTrack;
  final bool fakeIsPlaying;
  final Duration fakePosition;
  final Duration? fakeDuration;
  final Set<String> nullImportPaths;
  final Set<String> throwImportPaths;
  final importedPaths = <String>[];

  @override
  List<AudioTrack> get filteredTracks => fakeTracks;

  @override
  List<AudioTrack> get tracks => fakeTracks;

  @override
  bool get isLoading => false;

  @override
  AudioTrack? get activeTrack => fakeActiveTrack;

  @override
  bool get isPlaying => fakeIsPlaying;

  @override
  Duration get position => fakePosition;

  @override
  Duration? get duration => fakeDuration;

  @override
  Future<void> loadTracks() async {}

  @override
  Future<int?> importTrackFromPath(String filePath) async {
    importedPaths.add(filePath);
    if (throwImportPaths.contains(filePath)) {
      throw StateError('Import failed');
    }
    if (nullImportPaths.contains(filePath)) return null;
    return importedPaths.length;
  }

  @override
  Future<void> playTrack(AudioTrack track) async {}

  @override
  Future<void> togglePlayPause() async {}

  @override
  Future<void> archiveTrack(int id) async {}
}

class FakeFilePicker extends FilePicker {
  FakeFilePicker(this.result, {this.error});

  final FilePickerResult? result;
  final Object? error;
  FileType? pickedType;
  List<String>? pickedAllowedExtensions;
  bool? pickedAllowMultiple;

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
    pickedAllowMultiple = allowMultiple;
    final error = this.error;
    if (error != null) throw error;
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

  Future<void> pumpTavern(
    WidgetTester tester,
    FakeTavernProvider provider,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TavernProvider>.value(
        value: provider,
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TavernScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows audio empty state and import action', (tester) async {
    await pumpTavern(tester, FakeTavernProvider(fakeTracks: const []));

    expect(find.byKey(const Key('tavern-search-field')), findsOneWidget);
    expect(find.text('No audio yet'), findsOneWidget);
    expect(
      find.text('Import audio to build your local tavern library.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Import audio'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('renders track metadata and mini player when active', (
    tester,
  ) async {
    final activeTrack = AudioTrack(
      id: 1,
      title: 'Ember Waltz',
      artist: 'Inn Bard',
      album: 'Evening Set',
      filePath: '/tmp/ember-waltz.mp3',
      durationMs: 200000,
      positionMs: 50000,
    );

    await pumpTavern(
      tester,
      FakeTavernProvider(
        fakeTracks: [activeTrack],
        fakeActiveTrack: activeTrack,
        fakeIsPlaying: true,
        fakePosition: const Duration(seconds: 50),
        fakeDuration: const Duration(seconds: 200),
      ),
    );

    expect(find.text('Ember Waltz'), findsNWidgets(2));
    expect(find.text('Inn Bard · Evening Set'), findsOneWidget);
    expect(find.text('Now playing'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows import failure message and continues remaining files', (
    tester,
  ) async {
    final filePicker = FakeFilePicker(
      FilePickerResult([
        PlatformFile(name: 'ok.mp3', path: '/tmp/ok.mp3', size: 1),
        PlatformFile(name: 'null.mp3', path: '/tmp/null.mp3', size: 1),
        PlatformFile(name: 'throws.mp3', path: '/tmp/throws.mp3', size: 1),
        PlatformFile(name: 'after.mp3', path: '/tmp/after.mp3', size: 1),
      ]),
    );
    overrideFilePicker(filePicker);

    final provider = FakeTavernProvider(
      fakeTracks: const [],
      nullImportPaths: const {'/tmp/null.mp3'},
      throwImportPaths: const {'/tmp/throws.mp3'},
    );
    await pumpTavern(tester, provider);

    await tester.tap(find.byTooltip('Import audio'));
    await tester.pump();

    expect(filePicker.pickedType, FileType.custom);
    expect(filePicker.pickedAllowMultiple, isTrue);
    expect(filePicker.pickedAllowedExtensions, [
      'mp3',
      'm4a',
      'aac',
      'wav',
      'ogg',
      'flac',
    ]);
    expect(provider.importedPaths, [
      '/tmp/ok.mp3',
      '/tmp/null.mp3',
      '/tmp/throws.mp3',
      '/tmp/after.mp3',
    ]);
    expect(find.text('Selected audio file is unavailable.'), findsOneWidget);
  });

  testWidgets('shows import failure message when file picker throws', (
    tester,
  ) async {
    final filePicker = FakeFilePicker(null, error: StateError('Picker failed'));
    overrideFilePicker(filePicker);

    final provider = FakeTavernProvider(fakeTracks: const []);
    await pumpTavern(tester, provider);

    await tester.tap(find.byTooltip('Import audio'));
    await tester.pump();

    expect(provider.importedPaths, isEmpty);
    expect(find.text('Selected audio file is unavailable.'), findsOneWidget);
  });

  tearDownAll(() {
    FilePicker.platform = filePickerBaseline;
  });
}
