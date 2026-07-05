import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/icon_registry.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reward.dart';
import '../../../providers/reward_provider.dart';
import '../../widgets/common/game_snack_bar.dart';
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
    return Consumer<RewardProvider>(
      builder: (context, rewards, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rewards Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RewardFormScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nova'),
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
                        onArchive: _archive,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _archive(Reward reward) async {
    if (reward.id == null) return;
    final rewardProvider = context.read<RewardProvider>();
    await rewardProvider.archiveReward(reward.id!);
    if (!mounted) return;
    GameSnackBar.show(
      context,
      message: rewardProvider.error ?? 'Recompensa arquivada.',
      type: rewardProvider.error == null
          ? GameSnackBarType.info
          : GameSnackBarType.error,
      title: rewardProvider.error == null ? 'Registro Atualizado' : 'Erro',
    );
  }
}

class _RewardsList extends StatelessWidget {
  final List<Reward> rewards;
  final ValueChanged<Reward> onArchive;

  const _RewardsList({required this.rewards, required this.onArchive});

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
        return _RewardTile(reward: reward, onArchive: () => onArchive(reward));
      },
    );
  }
}

class _RewardTile extends StatelessWidget {
  final Reward reward;
  final VoidCallback onArchive;

  const _RewardTile({required this.reward, required this.onArchive});

  @override
  Widget build(BuildContext context) {
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
              IconButton(
                tooltip: 'Arquivar',
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
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
