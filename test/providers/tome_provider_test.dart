import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:liferpg/data/database/database_helper.dart';
import 'package:liferpg/data/models/tome.dart';
import 'package:liferpg/providers/tome_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TomeProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper().resetForTesting();
    provider = TomeProvider();
  });

  test('loads tomes and filters by search query', () async {
    await provider.addTome(
      Tome(title: 'Flutter Tome', author: 'Mage', filePath: '/tmp/flutter.pdf'),
    );
    await provider.addTome(
      Tome(title: 'Cooking Notes', author: 'Chef', filePath: '/tmp/cook.pdf'),
    );

    provider.setSearchQuery('mage');

    expect(provider.filteredTomes, hasLength(1));
    expect(provider.filteredTomes.single.title, 'Flutter Tome');
  });

  test('updates and archives tomes', () async {
    final id = await provider.addTome(
      Tome(title: 'Draft Tome', filePath: '/tmp/draft.pdf'),
    );

    await provider.updateTome(
      provider.tomes.single.copyWith(currentPage: 3, totalPages: 10),
    );
    expect(provider.tomes.single.progress, 0.3);

    await provider.archiveTome(id!);
    expect(provider.tomes, isEmpty);
  });
}
