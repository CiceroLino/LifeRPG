import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/default_content_templates.dart';
import '../../../core/platform/custom_avatar_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/player.dart';
import '../../../providers/player_provider.dart';
import '../../widgets/common/avatar_image.dart';
import '../../widgets/profile/profile_icon_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _showAvatar = true;
  String? _avatarPath;
  bool _avatarSelectionInProgress = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isHydratingPlayer = false;
  int? _loadedPlayerId;
  String? _loadedPlayerFingerprint;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    _nameController.addListener(() => _setUnsaved(true));
    _titleController.addListener(() => _setUnsaved(true));
    _descriptionController.addListener(() => _setUnsaved(true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final player = context.read<PlayerProvider>().player;
    if (player == null) return;

    final nextFingerprint = _buildPlayerFingerprint(player);
    final shouldRefresh = _loadedPlayerFingerprint != nextFingerprint;
    if (!shouldRefresh) return;

    if (!_hasUnsavedChanges) {
      _hydrateFromPlayer(player);
      return;
    }

    if (!_avatarSelectionInProgress && _avatarPath != player.avatarPath) {
      _syncAvatarFromPlayer(player);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _buildPlayerFingerprint(Player player) {
    return '${player.id}|${player.name}|${player.title}|${player.description}|'
        '${player.avatarPath ?? ''}|${player.updatedAt.toIso8601String()}';
  }

  void _selectPresetClass(String className) {
    if (_titleController.text == className) return;
    _titleController.text = className;
    if (_loadedPlayerId == null) return;
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Widget _buildClassPresetChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classes sugeridas',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DefaultContentTemplates.profileClasses.map((preset) {
            final isSelected = _titleController.text == preset.name;
            return FilterChip(
              label: Text(preset.name),
              selected: isSelected,
              selectedColor: AppTheme.primary.withValues(alpha: 0.18),
              onSelected: (_) => _selectPresetClass(preset.name),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _hydrateFromPlayer(Player player) {
    if (_isHydratingPlayer) return;
    _isHydratingPlayer = true;
    setState(() {
      _nameController.text = player.name;
      _titleController.text = player.title;
      _descriptionController.text = player.description;
      _avatarPath = player.avatarPath;
      _avatarSelectionInProgress = false;
      _loadedPlayerId = player.id;
      _loadedPlayerFingerprint = _buildPlayerFingerprint(player);
      _hasUnsavedChanges = false;
      _isHydratingPlayer = false;
    });
  }

  void _syncAvatarFromPlayer(Player player) {
    if (_isHydratingPlayer) return;
    _isHydratingPlayer = true;
    setState(() {
      _avatarPath = player.avatarPath;
      _avatarSelectionInProgress = false;
      _loadedPlayerFingerprint = _buildPlayerFingerprint(player);
      _isHydratingPlayer = false;
    });
  }

  void _setUnsaved(bool value) {
    if (_isHydratingPlayer || _loadedPlayerId == null) return;
    if (_hasUnsavedChanges == value) return;
    setState(() {
      _hasUnsavedChanges = value;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final playerProvider = context.read<PlayerProvider>();
    final player = playerProvider.player;
    if (player == null) return;

    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome e título não podem ficar vazios.'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await playerProvider.updatePlayer(
        player.copyWith(
          name: name,
          title: title,
          description: description,
          avatarPath: _avatarPath,
        ),
      );
      if (!mounted) return;

      setState(() {
        _hasUnsavedChanges = false;
        _avatarSelectionInProgress = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil salvo com sucesso.'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar perfil: $error'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool?> _confirmDiscardChanges() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Descartar alterações',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Você fez alterações não salvas no perfil. Deseja sair sem salvar?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Descartar',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final avatarPath = await pickAndStoreCustomAvatar();
      if (avatarPath == null) return;
      setState(() {
        _avatarPath = avatarPath;
        _avatarSelectionInProgress = true;
        _hasUnsavedChanges = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar ícone: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _pickAvatarFromIconPicker() async {
    final selectedIcon = await showProfileIconPicker(
      context,
      currentIconPath: _avatarPath,
    );
    if (selectedIcon == null) return;

    setState(() {
      _avatarPath = selectedIcon;
      _avatarSelectionInProgress = true;
      _hasUnsavedChanges = true;
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppTheme.border, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppTheme.primary, width: 2),
      ),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppTheme.border, width: 1),
      ),
      contentPadding: const EdgeInsets.only(bottom: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, _) {
        final player = playerProvider.player;
        if (player == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final avatarPath = _avatarPath ?? player.avatarPath;

        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldDiscard = await _confirmDiscardChanges() == true;
            if (!context.mounted || !mounted || !shouldDiscard) return;
            setState(() => _hasUnsavedChanges = false);
            Navigator.of(context).pop();
          },
          child: Container(
            color: AppTheme.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _pickAvatarFromIconPicker,
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
                                    _showAvatar && avatarPath != null &&
                                        avatarPath.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: buildAvatarImage(
                                          avatarPath,
                                          placeholderBuilder: _buildAvatarPlaceholder,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _buildAvatarPlaceholder(),
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                  'Exibir avatar',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.border, width: 1),
                              ),
                              child: TextButton(
                                onPressed: _pickAvatarFromGallery,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(80, 36),
                                ),
                                child: const Text(
                                  'Personalizar',
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                validator: (value) => (value == null ||
                                        value.trim().isEmpty)
                                    ? 'Informe o nome do herói'
                                    : null,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                ),
                                decoration: _inputDecoration('Nome'),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _titleController,
                                validator: (value) => (value == null ||
                                        value.trim().isEmpty)
                                    ? 'Informe o título/classe'
                                    : null,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                ),
                                decoration: _inputDecoration('Título/Classe'),
                              ),
                              _buildClassPresetChips(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      maxLength: 250,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: _inputDecoration('Descrição do perfil').copyWith(
                        contentPadding: const EdgeInsets.only(top: 8),
                        helperText: 'Máximo de 250 caracteres.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            !_hasUnsavedChanges || _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Salvar alterações'),
                      ),
                    ),
                  ],
                ),
              ),
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
