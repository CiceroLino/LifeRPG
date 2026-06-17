import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/icon_registry.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reward.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/reward_provider.dart';
import '../../widgets/common/game_snack_bar.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RewardProvider>().loadRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RewardProvider, PlayerProvider>(
      builder: (context, rewards, playerProvider, _) {
        final player = playerProvider.player;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Shop',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.stars_rounded, size: 18),
                    label: Text('${player?.rewardPoints ?? 0} RP'),
                  ),
                ],
              ),
              if (rewards.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  rewards.error!,
                  style: const TextStyle(color: AppTheme.accentRed),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: rewards.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _ShopList(
                        rewards: rewards.rewards,
                        onPurchase: _purchase,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _purchase(Reward reward) async {
    if (reward.id == null) return;
    final rewardProvider = context.read<RewardProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final success = await rewardProvider.purchaseReward(reward.id!);
    if (success) {
      await playerProvider.loadPlayer();
      await inventoryProvider.loadItems();
    }
    if (!mounted) return;
    GameSnackBar.show(
      context,
      message: success
          ? '${reward.name} entrou no inventário.'
          : rewardProvider.error ?? 'Compra não concluída.',
      title: success ? 'Item Obtido' : 'Compra Falhou',
      type: success ? GameSnackBarType.reward : GameSnackBarType.error,
    );
  }
}

class _ShopList extends StatelessWidget {
  final List<Reward> rewards;
  final ValueChanged<Reward> onPurchase;

  const _ShopList({required this.rewards, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma recompensa disponível na loja.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: rewards.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return _ShopRewardTile(
          reward: reward,
          onPurchase: () => onPurchase(reward),
        );
      },
    );
  }
}

class _ShopRewardTile extends StatelessWidget {
  final Reward reward;
  final VoidCallback onPurchase;

  const _ShopRewardTile({required this.reward, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    final inStock = reward.isUnlimitedStock || (reward.stockRemaining ?? 0) > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.18),
            foregroundColor: AppTheme.accentAmber,
            child: Icon(LifeRPGIcons.rewardIconFor(reward.icon)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reward.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reward.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(label: '${reward.priceRp} RP'),
                    _MetaChip(
                      label: reward.isUnlimitedStock
                          ? 'Estoque ilimitado'
                          : 'Estoque: ${reward.stockRemaining ?? 0}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: inStock ? onPurchase : null,
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('Comprar'),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
