import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/icon_registry.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/inventory_item.dart';
import '../../../providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InventoryProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (inventory.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  inventory.error!,
                  style: const TextStyle(color: AppTheme.accentRed),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: inventory.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _InventoryList(
                        items: inventory.items,
                        onUse: (item) => _consume(item),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _consume(InventoryItem item) async {
    await context.read<InventoryProvider>().consumeItem(item.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} usado.')));
  }
}

class _InventoryList extends StatelessWidget {
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onUse;

  const _InventoryList({required this.items, required this.onUse});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum item no inventário.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 172,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _InventoryTile(item: item, onUse: () => onUse(item));
      },
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onUse;

  const _InventoryTile({required this.item, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        color: AppTheme.surface,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LifeRPGIcons.rewardIconFor(item.icon),
                color: AppTheme.accentAmber,
              ),
              const Spacer(),
              Text(
                'x${item.quantity}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUse,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Usar'),
            ),
          ),
        ],
      ),
    );
  }
}
