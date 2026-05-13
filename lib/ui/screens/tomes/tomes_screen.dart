import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/tome.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/tome_provider.dart';

class TomesScreen extends StatefulWidget {
  const TomesScreen({super.key});

  @override
  State<TomesScreen> createState() => _TomesScreenState();
}

class _TomesScreenState extends State<TomesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TomeProvider>().loadTomes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<TomeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tomes = provider.filteredTomes;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('tome-search-field'),
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surface,
                        hintText: l10n.translate('search_tomes'),
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textSecondary,
                        ),
                        suffixIcon: provider.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l10n.translate('search_clear'),
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.translate('import_tome'),
                    icon: const Icon(Icons.upload_file),
                    onPressed: () => _pickTome(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tomes.isEmpty
                  ? _TomeEmptyState(
                      message: provider.searchQuery.isEmpty
                          ? l10n.translate('no_tomes_yet')
                          : l10n.translate('no_tomes_found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                      itemCount: tomes.length,
                      itemBuilder: (context, index) {
                        final tome = tomes[index];
                        return _TomeCard(
                          tome: tome,
                          onOpen: () => _openTome(context, tome),
                          onEdit: () => _showTomeDialog(context, tome: tome),
                          onArchive: tome.id == null
                              ? null
                              : () => provider.archiveTome(tome.id!),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickTome(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (!context.mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) {
      _showMessage(context, l10n.translate('tome_file_unavailable'));
      return;
    }

    final title = p.basenameWithoutExtension(path);
    await context.read<TomeProvider>().addTome(
      Tome(
        title: title.isEmpty ? l10n.translate('untitled_tome') : title,
        filePath: path,
      ),
    );
  }

  Future<void> _openTome(BuildContext context, Tome tome) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.file(tome.filePath);
    final opened = await launchUrl(uri);
    if (!context.mounted) return;
    if (!opened) {
      _showMessage(context, l10n.translate('tome_open_failed'));
      return;
    }
    if (tome.id != null) {
      await context.read<TomeProvider>().markOpened(tome.id!);
    }
  }

  Future<void> _showTomeDialog(BuildContext context, {Tome? tome}) async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController(text: tome?.title ?? '');
    final authorController = TextEditingController(text: tome?.author ?? '');
    final descriptionController = TextEditingController(
      text: tome?.description ?? '',
    );
    final currentPageController = TextEditingController(
      text: tome?.currentPage == null ? '' : tome!.currentPage.toString(),
    );
    final totalPagesController = TextEditingController(
      text: tome?.totalPages?.toString() ?? '',
    );
    final provider = context.read<TomeProvider>();

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(l10n.translate('edit_tome')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('tome-title-field'),
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.translate('tome_title'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('tome_author'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.translate('description'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: currentPageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.translate('current_page'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: totalPagesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.translate('total_pages'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.translate('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.translate('save')),
              ),
            ],
          ),
        ) ??
        false;

    final title = titleController.text.trim();
    final author = authorController.text.trim();
    final description = descriptionController.text.trim();
    final currentPage = int.tryParse(currentPageController.text.trim()) ?? 0;
    final totalPages = int.tryParse(totalPagesController.text.trim());
    titleController.dispose();
    authorController.dispose();
    descriptionController.dispose();
    currentPageController.dispose();
    totalPagesController.dispose();

    if (!shouldSave || tome == null || title.isEmpty) return;
    await provider.updateTome(
      tome.copyWith(
        title: title,
        author: author,
        description: description,
        currentPage: currentPage < 0 ? 0 : currentPage,
        totalPages: totalPages != null && totalPages > 0 ? totalPages : null,
        clearTotalPages: totalPages == null || totalPages <= 0,
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _TomeEmptyState extends StatelessWidget {
  const _TomeEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              color: AppTheme.textSecondary,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('tomes_empty_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TomeCard extends StatelessWidget {
  const _TomeCard({
    required this.tome,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
  });

  final Tome tome;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (tome.progress * 100).round();
    final pageLabel = tome.totalPages == null
        ? l10n
              .translate('current_page_label')
              .replaceFirst('{page}', tome.currentPage.toString())
        : l10n
              .translate('page_progress_label')
              .replaceFirst('{current}', tome.currentPage.toString())
              .replaceFirst('{total}', tome.totalPages.toString());

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tome.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (tome.author.isNotEmpty)
                    Text(
                      tome.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  if (tome.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tome.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tome.totalPages == null ? null : tome.progress,
                      minHeight: 5,
                      backgroundColor: AppTheme.background,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tome.totalPages == null
                        ? pageLabel
                        : '$pageLabel · $percent%',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.translate('open_tome'),
              icon: const Icon(Icons.open_in_new),
              onPressed: onOpen,
            ),
            PopupMenuButton<String>(
              tooltip: l10n.translate('more_options'),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'archive') onArchive?.call();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.translate('edit')),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(l10n.translate('archive')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
