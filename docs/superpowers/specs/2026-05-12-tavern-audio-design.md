# Tavern Audio Design

## Goal

Add phase 3 as `Tavern`: a local-first audio library and player for LifeRPG. This phase focuses only on audio files. Video playback, video-as-audio, playlists, streaming, equalizer controls, lyrics, and advanced queue management are out of scope.

## Product Shape

- `Tavern` appears as a first-class navigation destination after `Tomes`.
- The screen uses a library-first layout: search and import controls at the top, a compact track list in the main area, and a mini player fixed at the bottom.
- Users can import local audio files through the platform file picker.
- Users can search tracks by title, artist, album, or file name.
- Tapping a track starts playback.
- The mini player shows the active track, play/pause, and basic progress.
- Mobile playback must support background audio through the platform media session/notification/lock screen path.
- The library starts empty. No seeded tracks are created.

## Data Model

SQLite adds `audio_tracks` in the next schema version.

Track fields:

- `id`
- `title`
- `artist`
- `album`
- `file_path`
- `duration_ms`
- `position_ms`
- `is_active`
- `last_played_at`
- `created_at`
- `updated_at`

Backup/restore includes `audio_tracks` metadata only. Audio files remain external local files and are not copied into backup payloads.

## Architecture

- Data layer:
  - `AudioTrack` model with `toMap`, `fromMap`, `copyWith`.
  - `AudioTrackRepository` for CRUD, archive, search/list, and playback progress persistence.
- State layer:
  - `TavernProvider` owns library state, search query, active track metadata, playback state, and operations exposed to the UI.
- Playback layer:
  - `TavernAudioService` wraps `audio_service` and `just_audio`.
  - The service is responsible for loading a local file, play/pause/seek, emitting playback state, and exposing media metadata to Android/iOS background controls.
- UI layer:
  - `TavernScreen` renders library search/import/list and the bottom mini player.
  - The UI calls provider APIs only; it does not manipulate the audio engine directly.

## Dependency Direction

UI -> `TavernProvider` -> repository and playback service.

The provider translates playback events into UI state. Repositories do not depend on player packages. Playback service does not depend on Flutter widgets.

## UX Details

- Empty state: show a Tavern-themed icon and a short message that importing audio starts the library.
- Import action: use `FilePicker.platform.pickFiles` with audio extensions.
- Track card: title, artist/album when available, duration when known, and last-played/progress affordance when available.
- Mini player: hidden when no track has been selected; visible once a track is active.
- Errors: failed import or failed playback should show a snack bar and leave the app usable.
- File missing: if a stored local file no longer exists or cannot be played, show an error and keep the track in the library so the user can edit/archive it later.

## Technical Choices

Use `just_audio` for local playback and `audio_service` for background/mobile media session integration.

This is more work than an in-app-only player, but it matches the phase requirement: audio should continue through the supported mobile background path. A pure `just_audio` implementation is not sufficient for this phase.

## Testing

- Repository tests:
  - create/update/list/archive tracks
  - persist playback position metadata
  - backup/restore preserves audio track metadata
- Provider tests:
  - load/filter tracks
  - import metadata path into a track through a provider-level operation that can be tested without invoking native file picker
  - playback state transitions can be tested with a fake playback service
- Widget tests:
  - empty state and import action render
  - track list renders metadata
  - mini player renders when provider exposes an active track

## Non-Goals

- No video support in this phase.
- No playlist authoring.
- No cloud storage or streaming URLs.
- No embedded file copying into app documents.
- No automatic metadata extraction requirement. If duration or tags are available through the playback layer, they may be stored opportunistically, but manual/local fallback labels must work.

