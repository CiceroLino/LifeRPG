import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/note.dart';
import '../../../data/models/notebook.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/notebook_provider.dart';

class NotebookDetailScreen extends StatefulWidget {
  const NotebookDetailScreen({super.key, required this.notebook});

  final Notebook notebook;

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.notebook.id != null) {
        context.read<NotebookProvider>().loadNotes(widget.notebook.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.notebook.name),
        actions: [
          IconButton(
            tooltip: l10n.translate('new_note'),
            icon: const Icon(Icons.note_add_outlined),
            onPressed: widget.notebook.id == null
                ? null
                : () => _showNoteDialog(context, widget.notebook.id!),
          ),
        ],
      ),
      body: Consumer<NotebookProvider>(
        builder: (context, provider, _) {
          final query = _query.trim().toLowerCase();
          final notes = query.isEmpty
              ? provider.notes
              : provider.notes
                    .where(
                      (note) =>
                          note.title.toLowerCase().contains(query) ||
                          note.body.toLowerCase().contains(query),
                    )
                    .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  key: const Key('note-search-field'),
                  onChanged: (value) => setState(() => _query = value),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surface,
                    hintText: l10n.translate('search_notes'),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Text(
                          query.isEmpty
                              ? l10n.translate('no_notes_yet')
                              : l10n.translate('no_notes_found'),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Card(
                            color: AppTheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              onTap: () => _showNoteDialog(
                                context,
                                widget.notebook.id!,
                                note: note,
                              ),
                              title: Text(note.title),
                              subtitle: note.body.isEmpty
                                  ? null
                                  : Text(
                                      note.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: IconButton(
                                tooltip: l10n.translate('delete'),
                                icon: const Icon(Icons.delete_outline),
                                onPressed: note.id == null
                                    ? null
                                    : () => provider.deleteNote(note.id!),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.translate('new_note'),
        onPressed: widget.notebook.id == null
            ? null
            : () => _showNoteDialog(context, widget.notebook.id!),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    int notebookId, {
    Note? note,
  }) async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: note?.body ?? '');
    final provider = context.read<NotebookProvider>();

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              note == null
                  ? l10n.translate('new_note')
                  : l10n.translate('edit_note'),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('note-title-field'),
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.translate('note_title'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    minLines: 6,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: l10n.translate('note_body'),
                      border: const OutlineInputBorder(),
                    ),
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
    final body = bodyController.text.trim();
    titleController.dispose();
    bodyController.dispose();

    if (!shouldSave || title.isEmpty) return;
    if (note == null) {
      await provider.addNote(
        Note(notebookId: notebookId, title: title, body: body),
      );
    } else {
      await provider.updateNote(note.copyWith(title: title, body: body));
    }
  }
}
