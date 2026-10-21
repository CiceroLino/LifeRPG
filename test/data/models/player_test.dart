import 'package:flutter_test/flutter_test.dart';

import 'package:liferpg/data/models/player.dart';

void main() {
  test('copyWith can clear nullable profile and energy schedule fields', () {
    final player = Player(
      avatarPath: '/tmp/avatar.png',
      wakeUpTime: '07:00',
      sleepTime: '23:00',
    );

    final updated = player.copyWith(
      avatarPath: null,
      wakeUpTime: null,
      sleepTime: null,
    );

    expect(updated.avatarPath, isNull);
    expect(updated.wakeUpTime, isNull);
    expect(updated.sleepTime, isNull);
  });
}
