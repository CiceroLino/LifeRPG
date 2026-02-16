import 'package:flutter/foundation.dart';
import '../data/models/player.dart';
import '../data/repositories/player_repository.dart';
import '../core/utils/xp_calculator.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerRepository _playerRepo = PlayerRepository();

  Player? _player;
  bool _isLoading = false;

  Player? get player => _player;
  bool get isLoading => _isLoading;

  int get totalXP => _player?.totalXP ?? 0;
  int get level => _player?.level ?? 1;
  int get xpForNextLevel => XPCalculator.xpForNextLevel(level);
  int get xpInCurrentLevel => XPCalculator.xpInCurrentLevel(totalXP, level);

  double get progressToNextLevel {
    if (_player == null || xpForNextLevel == 0) return 0.0;
    return xpInCurrentLevel / xpForNextLevel;
  }

  Future<void> loadPlayer() async {
    _isLoading = true;
    notifyListeners();

    try {
      _player = await _playerRepo.get();
    } catch (e) {
      debugPrint('Erro ao carregar player: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlayer(Player player) async {
    try {
      await _playerRepo.update(player);
      await loadPlayer();
    } catch (e) {
      debugPrint('Erro ao atualizar player: $e');
    }
  }

  Future<void> setEnergyMode(String mode) async {
    if (mode != 'manual' && mode != 'auto') return;
    final current = _player;
    if (current == null) return;
    await updatePlayer(current.copyWith(energyMode: mode));
  }

  Future<void> setWakeUpTime(String wakeUpTime) async {
    final current = _player;
    if (current == null) return;
    await updatePlayer(current.copyWith(wakeUpTime: wakeUpTime));
  }

  Future<void> setSleepTime(String sleepTime) async {
    final current = _player;
    if (current == null) return;
    await updatePlayer(current.copyWith(sleepTime: sleepTime));
  }

  Future<void> setManualEnergy(int value) async {
    final current = _player;
    if (current == null) return;
    await updatePlayer(current.copyWith(currentEnergy: value.clamp(0, 100)));
  }
}
