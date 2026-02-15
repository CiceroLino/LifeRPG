import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/theme/app_theme.dart';
import '../../../providers/player_provider.dart';
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
                                    child: player.avatarPath!.endsWith('.svg')
                                        ? SvgPicture.asset(
                                            player.avatarPath!,
                                            fit: BoxFit.contain,
                                            colorFilter: const ColorFilter.mode(
                                              AppTheme.textPrimary,
                                              BlendMode.srcIn,
                                            ),
                                            placeholderBuilder: (_) =>
                                                _buildAvatarPlaceholder(),
                                            errorBuilder: (_, __, ___) =>
                                                _buildAvatarPlaceholder(),
                                          )
                                        : player.avatarPath!.startsWith('/') ||
                                              player.avatarPath!.startsWith(
                                                'file://',
                                              )
                                        ? Image.file(
                                            File(
                                              player.avatarPath!.replaceFirst(
                                                'file://',
                                                '',
                                              ),
                                            ),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildAvatarPlaceholder(),
                                          )
                                        : Image.asset(
                                            player.avatarPath!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildAvatarPlaceholder(),
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
                              // Abre o explorador de arquivos para selecionar um ícone customizado
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.image,
                                    allowedExtensions: [
                                      'png',
                                      'jpg',
                                      'jpeg',
                                      'svg',
                                      'gif',
                                      'webp',
                                    ],
                                  );

                              if (result != null &&
                                  result.files.single.path != null &&
                                  mounted) {
                                final filePath = result.files.single.path!;

                                // Copia o arquivo para o diretório de documentos do app
                                try {
                                  final appDir =
                                      await getApplicationDocumentsDirectory();
                                  final customIconsDir = Directory(
                                    path.join(appDir.path, 'custom_icons'),
                                  );
                                  if (!await customIconsDir.exists()) {
                                    await customIconsDir.create(
                                      recursive: true,
                                    );
                                  }

                                  final fileName = path.basename(filePath);
                                  final destPath = path.join(
                                    customIconsDir.path,
                                    fileName,
                                  );
                                  final sourceFile = File(filePath);
                                  final destFile = await sourceFile.copy(
                                    destPath,
                                  );

                                  // Salva o caminho do arquivo copiado
                                  final updatedPlayer = player.copyWith(
                                    avatarPath: destFile.path,
                                  );
                                  await playerProvider.updatePlayer(
                                    updatedPlayer,
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao salvar ícone: $e',
                                        ),
                                        backgroundColor: AppTheme.accentRed,
                                      ),
                                    );
                                  }
                                }
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
