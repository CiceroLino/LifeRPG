import 'package:flutter/foundation.dart';

import '../data/models/reward.dart';
import '../data/repositories/reward_repository.dart';

class RewardProvider extends ChangeNotifier {
  final RewardRepository _rewardRepo = RewardRepository();

  List<Reward> _rewards = [];
  bool _isLoading = false;
  String? _error;

  List<Reward> get rewards => _rewards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRewards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rewards = await _rewardRepo.getActive();
    } catch (e) {
      _error = 'Erro ao carregar recompensas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadRewardsKeepingError() async {
    try {
      _rewards = await _rewardRepo.getActive();
    } catch (e) {
      _error ??= 'Erro ao carregar recompensas: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> addReward(Reward reward) async {
    try {
      _error = null;
      await _rewardRepo.insert(reward);
      await loadRewards();
    } catch (e) {
      _error = 'Erro ao salvar recompensa: $e';
      notifyListeners();
    }
  }

  Future<void> updateReward(Reward reward) async {
    try {
      _error = null;
      await _rewardRepo.update(reward);
      await loadRewards();
    } catch (e) {
      _error = 'Erro ao atualizar recompensa: $e';
      notifyListeners();
    }
  }

  Future<void> archiveReward(int id) async {
    try {
      _error = null;
      await _rewardRepo.archive(id);
      await loadRewards();
    } catch (e) {
      _error = 'Erro ao arquivar recompensa: $e';
      notifyListeners();
    }
  }

  Future<bool> purchaseReward(int id) async {
    try {
      _error = null;
      await _rewardRepo.purchaseReward(id);
      await loadRewards();
      return true;
    } on InsufficientRewardPointsException {
      _error = 'RP insuficiente para comprar esta recompensa.';
      await _reloadRewardsKeepingError();
      return false;
    } on RewardOutOfStockException {
      _error = 'Recompensa sem estoque disponível.';
      await _reloadRewardsKeepingError();
      return false;
    } on RewardUnavailableException {
      _error = 'Recompensa indisponível.';
      await _reloadRewardsKeepingError();
      return false;
    } catch (e) {
      _error = 'Erro ao comprar recompensa: $e';
      await _reloadRewardsKeepingError();
      return false;
    }
  }
}
