import '../data/database/data_operations.dart';
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

  Future<void> loadPlayer() => DataOperations.instance.run(() async {
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
  }, readOnly: true);

  Future<void> updatePlayer(Player player) =>
      DataOperations.instance.run(() async {
        try {
          await _playerRepo.updateProfile(player);
          await loadPlayer();
        } catch (e) {
          debugPrint('Erro ao atualizar player: $e');
          rethrow;
        }
      }, readOnly: false);

  Future<void> setEnergyMode(String mode) =>
      DataOperations.instance.run(() async {
        if (mode != 'manual' && mode != 'auto') return;
        final current = _player;
        if (current == null) return;
        await _playerRepo.updateEnergy(mode: mode);
        await loadPlayer();
      }, readOnly: false);

  Future<void> setWakeUpTime(String wakeUpTime) =>
      DataOperations.instance.run(() async {
        final current = _player;
        if (current == null) return;
        await _playerRepo.updateEnergy(wakeUpTime: wakeUpTime);
        await loadPlayer();
      }, readOnly: false);

  Future<void> setSleepTime(String sleepTime) =>
      DataOperations.instance.run(() async {
        final current = _player;
        if (current == null) return;
        await _playerRepo.updateEnergy(sleepTime: sleepTime);
        await loadPlayer();
      }, readOnly: false);

  Future<void> setManualEnergy(int value) =>
      DataOperations.instance.run(() async {
        final current = _player;
        if (current == null) return;
        await _playerRepo.updateEnergy(value: value);
        await loadPlayer();
      }, readOnly: false);
}
