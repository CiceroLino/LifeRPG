import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/default_content_templates.dart';
import '../../../core/constants/icon_registry.dart';
import '../../../data/models/reward.dart';
import '../../../providers/reward_provider.dart';

class RewardFormScreen extends StatefulWidget {
  final Reward? reward;

  const RewardFormScreen({super.key, this.reward});

  @override
  State<RewardFormScreen> createState() => _RewardFormScreenState();
}

class _RewardFormScreenState extends State<RewardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  String _icon = 'card_giftcard';
  bool _isUnlimitedStock = true;

  @override
  void initState() {
    super.initState();
    final reward = widget.reward;
    _nameController = TextEditingController(text: reward?.name ?? '');
    _descriptionController = TextEditingController(
      text: reward?.description ?? '',
    );
    _priceController = TextEditingController(
      text: reward?.priceRp.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: reward?.stockRemaining?.toString() ?? '',
    );
    final storedIcon = reward?.icon;
    final isKnownIcon = LifeRPGIcons.rewardOptions.any(
      (option) => option.key == storedIcon,
    );
    _icon = isKnownIcon ? storedIcon! : 'card_giftcard';
    _isUnlimitedStock = reward?.isUnlimitedStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reward != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar recompensa' : 'Nova recompensa'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!isEditing) ...[
                _RewardTemplatePicker(onSelected: _applyRewardTemplate),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const Key('reward-name-field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('reward-price-field'),
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Preço em RP'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Informe um preço válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_icon),
                initialValue: _icon,
                decoration: const InputDecoration(labelText: 'Ícone'),
                items: LifeRPGIcons.rewardOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.key,
                        child: Row(
                          children: [
                            Icon(option.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(option.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _icon = value);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Estoque ilimitado'),
                value: _isUnlimitedStock,
                onChanged: (value) {
                  setState(() => _isUnlimitedStock = value);
                },
              ),
              if (!_isUnlimitedStock) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('reward-stock-field'),
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Estoque'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isUnlimitedStock) return null;
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Informe um estoque válido.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyRewardTemplate(RewardTemplate template) {
    setState(() {
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _priceController.text = template.priceRp.toString();
      _icon = template.icon;
      _isUnlimitedStock = true;
      _stockController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final reward = Reward(
      id: widget.reward?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      priceRp: int.parse(_priceController.text),
      isUnlimitedStock: _isUnlimitedStock,
      stockRemaining: _isUnlimitedStock
          ? null
          : int.parse(_stockController.text),
      icon: _icon,
      isActive: widget.reward?.isActive ?? true,
      createdAt: widget.reward?.createdAt,
    );

    final provider = context.read<RewardProvider>();
    if (widget.reward == null) {
      await provider.addReward(reward);
    } else {
      await provider.updateReward(reward);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _RewardTemplatePicker extends StatelessWidget {
  final ValueChanged<RewardTemplate> onSelected;

  const _RewardTemplatePicker({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DefaultContentTemplates.rewardTemplates
          .map(
            (template) => ActionChip(
              avatar: Icon(
                LifeRPGIcons.rewardIconFor(template.icon),
                size: 16,
              ),
              label: Text(template.label),
              onPressed: () => onSelected(template),
            ),
          )
          .toList(),
    );
  }
}
