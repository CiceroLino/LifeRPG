# Product TODOs and Deprecations Design

## Scope
Implement all remaining product TODOs and migrate deprecated Flutter/Dart usage identified by analyzer.

## Product Work
- Main app actions: profile edit routing, calendar interaction, workspace switching feedback, avatar reset, profile sharing, data export, history clearing.
- Settings provider: functional `resetCharacter` and `factoryReset`.
- Mission editor: skills selector, parent mission selector, reward integration.
- Player header: real-time left display derived from player schedule/energy mode.

## Technical Quality Work
- Remove deprecated API usage (`withOpacity`, Radio APIs, `LinearStrokeCap`).
- Resolve async context lint warnings.
- Resolve unnecessary underscore parameter lint warnings.

## Data & Behavior
- Add DB helper reset operations for character-only reset and full factory reset.
- Keep mission/skill/player existing architecture; integrate behavior through existing providers.

## Validation
- `flutter analyze` clean.
- Full test suite passing.
