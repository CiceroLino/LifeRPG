import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/reward.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/reward_provider.dart';
import 'reward_form_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RewardProvider>().loadRewards();
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
                      'Rewards',
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
                    : _RewardsList(
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
    final rewardProvider = context.read<RewardProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final success = await rewardProvider.purchaseReward(reward.id!);
    if (success) {
      await playerProvider.loadPlayer();
      await inventoryProvider.loadItems();
    }
    if (!mounted) return;
    final message = success
        ? 'Recompensa enviada para o Inventory.'
        : rewardProvider.error ?? 'Compra não concluída.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RewardsList extends StatelessWidget {
  final List<Reward> rewards;
  final ValueChanged<Reward> onPurchase;

  const _RewardsList({required this.rewards, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma recompensa cadastrada.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: rewards.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return _RewardTile(
          reward: reward,
          onPurchase: () => onPurchase(reward),
        );
      },
    );
  }
}

class _RewardTile extends StatelessWidget {
  final Reward reward;
  final VoidCallback onPurchase;

  const _RewardTile({required this.reward, required this.onPurchase});

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
            child: Icon(_iconFor(reward.icon)),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Editar',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RewardFormScreen(reward: reward),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              FilledButton(
                onPressed: inStock ? onPurchase : null,
                child: const Text('Comprar'),
              ),
            ],
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

IconData _iconFor(String? icon) {
  return switch (icon) {
    'movie' => Icons.movie_outlined,
    'local_cafe' => Icons.local_cafe_outlined,
    'sports_esports' => Icons.sports_esports_outlined,
    'menu_book' => Icons.menu_book_outlined,
    _ => Icons.card_giftcard_outlined,
  };
}
