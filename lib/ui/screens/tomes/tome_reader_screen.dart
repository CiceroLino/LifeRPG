import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/tome.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/tome_provider.dart';

class TomeReaderScreen extends StatefulWidget {
  const TomeReaderScreen({super.key, required this.tome});

  final Tome tome;

  @override
  State<TomeReaderScreen> createState() => _TomeReaderScreenState();
}

class _TomeReaderScreenState extends State<TomeReaderScreen> {
  late int _currentPage = widget.tome.currentPage <= 0
      ? 1
      : widget.tome.currentPage;
  int? _totalPages;
  int? _lastPersistedPage;
  int? _lastPersistedTotalPages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalPages = _totalPages ?? widget.tome.totalPages;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.tome.title, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                totalPages == null
                    ? l10n
                          .translate('current_page_label')
                          .replaceFirst('{page}', _currentPage.toString())
                    : l10n
                          .translate('page_progress_label')
                          .replaceFirst('{current}', _currentPage.toString())
                          .replaceFirst('{total}', totalPages.toString()),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: PdfViewer.file(
        widget.tome.filePath,
        initialPageNumber: _currentPage,
        params: PdfViewerParams(
          backgroundColor: AppTheme.background,
          margin: 8,
          onViewerReady: (document, controller) {
            final pageCount = controller.pageCount;
            if (mounted) {
              setState(() => _totalPages = pageCount);
            }
            _persistProgress(currentPage: _currentPage, totalPages: pageCount);
            final id = widget.tome.id;
            if (id != null) {
              unawaited(context.read<TomeProvider>().markOpened(id));
            }
          },
          onPageChanged: (pageNumber) {
            if (pageNumber == null) return;
            if (mounted) {
              setState(() => _currentPage = pageNumber);
            } else {
              _currentPage = pageNumber;
            }
            _persistProgress(currentPage: pageNumber, totalPages: _totalPages);
          },
          errorBannerBuilder: (context, error, stackTrace, documentRef) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.translate('tome_open_failed'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _persistProgress({required int currentPage, int? totalPages}) {
    final id = widget.tome.id;
    if (id == null) return;
    if (_lastPersistedPage == currentPage &&
        _lastPersistedTotalPages == totalPages) {
      return;
    }

    _lastPersistedPage = currentPage;
    _lastPersistedTotalPages = totalPages;
    unawaited(
      context.read<TomeProvider>().updateReadingProgress(
        id,
        currentPage: currentPage,
        totalPages: totalPages,
      ),
    );
  }
}
