import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/platform/custom_avatar_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/player_provider.dart';
import '../../widgets/common/avatar_image.dart';
import '../../widgets/profile/profile_icon_picker.dart';

/// Tela de perfil do jogador com layout de edição fiel ao design original.
/// Header persistente (PlayerStatsHeader) é gerenciado pelo MainScreen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _showAvatar = true;

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerProvider>().player;
    _nameController = TextEditingController(text: player?.name ?? 'Player');
    _titleController = TextEditingController(
      text: player?.title ?? 'Adventurer',
    );
    _descriptionController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, _) {
        final player = playerProvider.player;
        if (player == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          color: AppTheme.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Layout de Edição: Avatar + Checkbox + Botão CUSTOM
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Esquerda: Ícone do avatar grande (branco) - clicável para selecionar ícone
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Abre o seletor de ícones da aplicação
                            final selectedIcon = await showProfileIconPicker(
                              context,
                              currentIconPath: player.avatarPath,
                            );
                            if (selectedIcon != null && mounted) {
                              final updatedPlayer = player.copyWith(
                                avatarPath: selectedIcon,
                              );
                              await playerProvider.updatePlayer(updatedPlayer);
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.border,
                                width: 1,
                              ),
                            ),
                            child:
                                _showAvatar &&
                                    player.avatarPath != null &&
                                    player.avatarPath!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: buildAvatarImage(
                                      player.avatarPath!,
                                      placeholderBuilder:
                                          _buildAvatarPlaceholder,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _buildAvatarPlaceholder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Checkbox "Show"
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showAvatar,
                              onChanged: (value) {
                                setState(() {
                                  _showAvatar = value ?? true;
                                });
                              },
                              activeColor: AppTheme.primary,
                              checkColor: Colors.white,
                            ),
                            const Text(
                              'Show',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Botão retangular cinza com borda tracejada [ ] CUSTOM
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.border,
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              try {
                                final avatarPath =
                                    await pickAndStoreCustomAvatar();
                                if (avatarPath == null || !mounted) {
                                  return;
                                }

                                final updatedPlayer = player.copyWith(
                                  avatarPath: avatarPath,
                                );
                                await playerProvider.updatePlayer(
                                  updatedPlayer,
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao salvar ícone: $e'),
                                    backgroundColor: AppTheme.accentRed,
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(80, 36),
                            ),
                            child: const Text(
                              '[ ] CUSTOM',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Direita: TextFields com underline
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TextField "Name"
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.border,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.border,
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.only(bottom: 8),
                            ),
                            onSubmitted: (value) async {
                              if (value.trim().isNotEmpty) {
                                final updatedPlayer = player.copyWith(
                                  name: value.trim(),
                                );
                                await playerProvider.updatePlayer(
                                  updatedPlayer,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          // TextField "Title/Class"
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Title/Class',
                              labelStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.border,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.border,
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.only(bottom: 8),
                            ),
                            onSubmitted: (value) async {
                              if (value.trim().isNotEmpty) {
                                final updatedPlayer = player.copyWith(
                                  title: value.trim(),
                                );
                                await playerProvider.updatePlayer(
                                  updatedPlayer,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Campo de texto grande para "Description"
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.border, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.border, width: 1),
                    ),
                    contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.person, color: AppTheme.textPrimary, size: 40),
    );
  }
}
