import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/providers/mission_provider.dart';
import 'package:liferpg/ui/screens/missions/missions_list_screen.dart';

class FakeMissionProvider extends MissionProvider {
  FakeMissionProvider({required this.all, required this.filtered});

  final List<Mission> all;
  final List<Mission> filtered;

  @override
  bool get isLoading => false;

  @override
  List<Mission> get missions => all;

  @override
  List<Mission> get filteredMissions => filtered;

  @override
  Future<void> loadMissions() async {}
}

Mission _m(int id, String title) => Mission(id: id, title: title);

void main() {
  testWidgets('renders filtered missions list', (tester) async {
    final provider = FakeMissionProvider(
      all: [_m(1, 'Alpha Mission'), _m(2, 'Beta Mission')],
      filtered: [_m(2, 'Beta Mission')],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MissionProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: MissionsListScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Beta Mission'), findsOneWidget);
    expect(find.text('Alpha Mission'), findsNothing);
  });
}
