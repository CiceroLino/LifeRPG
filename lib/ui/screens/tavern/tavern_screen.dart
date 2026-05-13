import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/audio_track.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/tavern_provider.dart';

class TavernScreen extends StatefulWidget {
  const TavernScreen({super.key});

  @override
  State<TavernScreen> createState() => _TavernScreenState();
}

class _TavernScreenState extends State<TavernScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<TavernProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tracks = provider.filteredTracks;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('tavern-search-field'),
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surface,
                        hintText: l10n.translate('search_audio'),
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
                    tooltip: l10n.translate('import_audio'),
                    icon: const Icon(Icons.library_music_outlined),
                    onPressed: () => _pickAudio(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tracks.isEmpty
                  ? _TavernEmptyState(
                      message: provider.searchQuery.isEmpty
                          ? l10n.translate('no_audio_yet')
                          : l10n.translate('no_audio_found'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        8,
                        4,
                        8,
                        provider.activeTrack == null ? 16 : 112,
                      ),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _TrackCard(
                          track: track,
                          active: provider.activeTrack?.id == track.id,
                          onPlay: () => _playTrack(context, track),
                          onArchive: track.id == null
                              ? null
                              : () => provider.archiveTrack(track.id!),
                        );
                      },
                    ),
            ),
            if (provider.activeTrack != null)
              _MiniPlayer(
                track: provider.activeTrack!,
                isPlaying: provider.isPlaying,
                position: provider.position,
                duration: provider.duration,
                shuffleEnabled: provider.shuffleEnabled,
                repeatMode: provider.repeatMode,
                onPrevious: provider.playPreviousTrack,
                onTogglePlayPause: provider.togglePlayPause,
                onNext: provider.playNextTrack,
                onToggleShuffle: provider.toggleShuffle,
                onCycleRepeat: provider.cycleRepeatMode,
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickAudio(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
        allowMultiple: true,
        withReadStream: true,
      );
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, l10n.translate('audio_file_unavailable'));
      return;
    }
    if (!context.mounted || result == null || result.files.isEmpty) return;

    final provider = context.read<TavernProvider>();
    for (final file in result.files) {
      try {
        final importedId = await provider.importTrack(file);
        if (!context.mounted) return;
        if (importedId == null) {
          _showMessage(context, l10n.translate('audio_file_unavailable'));
        }
      } catch (_) {
        if (!context.mounted) return;
        _showMessage(context, l10n.translate('audio_file_unavailable'));
      }
      if (!context.mounted) return;
    }
  }

  Future<void> _playTrack(BuildContext context, AudioTrack track) async {
    final l10n = AppLocalizations.of(context);
    try {
      await context.read<TavernProvider>().playTrack(track);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, l10n.translate('audio_play_failed'));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _TavernEmptyState extends StatelessWidget {
  const _TavernEmptyState({required this.message});

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
              Icons.local_bar_outlined,
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
              l10n.translate('tavern_empty_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.active,
    required this.onPlay,
    required this.onArchive,
  });

  final AudioTrack track;
  final bool active;
  final VoidCallback onPlay;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: onPlay,
        leading: Icon(
          active ? Icons.equalizer : Icons.music_note_outlined,
          color: active ? AppTheme.primary : AppTheme.textSecondary,
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          _metadataLabel(track, l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: l10n.translate('more_options'),
          onSelected: (value) {
            if (value == 'archive') onArchive?.call();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'archive',
              child: Text(l10n.translate('archive')),
            ),
          ],
        ),
      ),
    );
  }

  String _metadataLabel(AudioTrack track, AppLocalizations l10n) {
    final artist = track.artist.trim();
    final album = track.album.trim();
    if (artist.isNotEmpty && album.isNotEmpty) return '$artist · $album';
    if (artist.isNotEmpty) return artist;
    if (album.isNotEmpty) return album;
    return l10n.translate('unknown_artist');
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.onPrevious,
    required this.onTogglePlayPause,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
  });

  final AudioTrack track;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final bool shuffleEnabled;
  final TavernRepeatMode repeatMode;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final durationValue = duration;
    final progress = durationValue == null || durationValue.inMilliseconds <= 0
        ? null
        : (position.inMilliseconds / durationValue.inMilliseconds)
              .clamp(0, 1)
              .toDouble();
    final repeatIcon = repeatMode == TavernRepeatMode.one
        ? Icons.repeat_one
        : Icons.repeat;
    final repeatTooltip = switch (repeatMode) {
      TavernRepeatMode.off => l10n.translate('repeat_off'),
      TavernRepeatMode.all => l10n.translate('repeat_all'),
      TavernRepeatMode.one => l10n.translate('repeat_one'),
    };

    return Material(
      color: AppTheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('now_playing'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: shuffleEnabled
                        ? l10n.translate('shuffle_on')
                        : l10n.translate('shuffle_off'),
                    icon: const Icon(Icons.shuffle),
                    color: shuffleEnabled ? AppTheme.primary : null,
                    onPressed: onToggleShuffle,
                  ),
                  IconButton(
                    tooltip: l10n.translate('previous_track'),
                    icon: const Icon(Icons.skip_previous),
                    onPressed: onPrevious,
                  ),
                  IconButton(
                    tooltip: isPlaying
                        ? l10n.translate('pause')
                        : l10n.translate('start'),
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: onTogglePlayPause,
                  ),
                  IconButton(
                    tooltip: l10n.translate('next_track'),
                    icon: const Icon(Icons.skip_next),
                    onPressed: onNext,
                  ),
                  IconButton(
                    tooltip: repeatTooltip,
                    icon: Icon(repeatIcon),
                    color: repeatMode == TavernRepeatMode.off
                        ? null
                        : AppTheme.primary,
                    onPressed: onCycleRepeat,
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppTheme.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
