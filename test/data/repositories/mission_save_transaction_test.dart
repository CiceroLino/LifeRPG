import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/data/repositories/mission_repository.dart';
import 'package:liferpg/providers/mission_provider.dart';
import '../../support/test_database.dart';

void main() {
  setUp(resetTestDatabase);
  test('failed mission links do not leave a partial mission on retry', () async {
    final provider = MissionProvider();
    final result = await provider.addMission(Mission(title: 'Invalid link', skillIds: [99999]));
    expect(result, isNull);
    expect(await MissionRepository().getAll(), isEmpty);
    provider.dispose();
  });
}
