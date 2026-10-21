import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferpg/data/models/mission.dart';
import 'package:liferpg/ui/widgets/mission/mission_card.dart';

Mission _mission() => Mission(
  id: 1,
  title: 'Study Flutter',
  description: 'Read docs',
  status: 'active',
  rewardPoints: 10,
  skillIds: const [1],
);

void main() {
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('shows expanded controls when expanded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MissionCard(mission: _mission(), isExpanded: true),
        ),
      ),
    );

    expect(find.byKey(const Key('mission-status-select')), findsOneWidget);
    expect(find.byKey(const Key('mission-edit-button')), findsOneWidget);
  });

  testWidgets('calls status callback when status changes', (tester) async {
    String? changedTo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MissionCard(
            mission: _mission(),
            isExpanded: true,
            onStatusChanged: (value) async {
              changedTo = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('mission-status-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();

    expect(changedTo, 'completed');
  });

  testWidgets('expanded card fits a small mobile viewport', (tester) async {
    setViewport(tester, const Size(360, 740));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              MissionCard(
                mission: _mission().copyWith(
                  title:
                      'Study Flutter layout constraints before the guild raid',
                  description:
                      'Read docs, inspect widgets, and avoid clipped quest actions.',
                  notes:
                      'A long quest note should wrap without forcing actions off screen.',
                  reminderNote: 'Bring the responsive layout checklist.',
                ),
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('mission-status-select')), findsOneWidget);
    expect(
      find.byKey(const Key('mission-quick-action-button')),
      findsOneWidget,
    );
  });
}
