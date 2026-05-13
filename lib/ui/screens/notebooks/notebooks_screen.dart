import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/notebook.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/notebook_provider.dart';
import 'notebook_detail_screen.dart';

class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotebookProvider>().loadNotebooks();
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
    return Consumer<NotebookProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final notebooks = provider.filteredNotebooks;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('notebook-search-field'),
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surface,
                        hintText: l10n.translate('search_notebooks'),
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
                    tooltip: l10n.translate('new_notebook'),
                    icon: const Icon(Icons.add),
                    onPressed: () => _showNotebookDialog(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notebooks.isEmpty
                  ? _NotebookEmptyState(
                      message: provider.searchQuery.isEmpty
                          ? l10n.translate('no_notebooks_yet')
                          : l10n.translate('no_notebooks_found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                      itemCount: notebooks.length,
                      itemBuilder: (context, index) {
                        final notebook = notebooks[index];
                        return _NotebookCard(
                          notebook: notebook,
                          noteCount:
                              provider.noteCountsByNotebook[notebook.id] ?? 0,
                          onTap: () => _openNotebook(context, notebook),
                          onEdit: () =>
                              _showNotebookDialog(context, notebook: notebook),
                          onArchive: notebook.id == null
                              ? null
                              : () => provider.archiveNotebook(notebook.id!),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNotebook(BuildContext context, Notebook notebook) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotebookDetailScreen(notebook: notebook),
      ),
    );
    if (!context.mounted) return;
    await context.read<NotebookProvider>().loadNotebooks();
  }

  Future<void> _showNotebookDialog(
    BuildContext context, {
    Notebook? notebook,
  }) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: notebook?.name ?? '');
    final descriptionController = TextEditingController(
      text: notebook?.description ?? '',
    );
    final provider = context.read<NotebookProvider>();

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              notebook == null
                  ? l10n.translate('new_notebook')
                  : l10n.translate('edit_notebook'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('notebook-name-field'),
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.translate('notebook_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('description'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
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

    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    nameController.dispose();
    descriptionController.dispose();

    if (!shouldSave || name.isEmpty) return;
    if (notebook == null) {
      await provider.addNotebook(
        Notebook(name: name, description: description),
      );
    } else {
      await provider.updateNotebook(
        notebook.copyWith(name: name, description: description),
      );
    }
  }
}

class _NotebookEmptyState extends StatelessWidget {
  const _NotebookEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
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
          ],
        ),
      ),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({
    required this.notebook,
    required this.noteCount,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
  });

  final Notebook notebook;
  final int noteCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countLabel = noteCount == 1
        ? l10n.translate('one_note')
        : l10n
              .translate('notes_count')
              .replaceFirst('{count}', noteCount.toString());

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.menu_book_outlined, color: AppTheme.primary),
        title: Text(
          notebook.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notebook.description.isNotEmpty) Text(notebook.description),
            Text(countLabel),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: l10n.translate('more_options'),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'archive') onArchive?.call();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.translate('edit'))),
            PopupMenuItem(
              value: 'archive',
              child: Text(l10n.translate('archive')),
            ),
          ],
        ),
      ),
    );
  }
}
