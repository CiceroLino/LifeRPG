# LifeRPG Agent Guide

## Documentation-First Context

Before changing behavior, read [docs/project-guide.md](docs/project-guide.md). It is the maintained source of truth for:

- Business rules for missions, XP, levels, skills, energy, rewards, inventory, backup, and reset flows.
- Design system and UI patterns used by the Flutter app.
- Architecture boundaries and files that usually own each concern.
- Testing expectations and high-risk areas.

Use this guide to avoid rediscovering project rules from scratch every session. If code and docs diverge, trust the code, then update the guide in the same change.

## Current Documentation Lookup Rule

Use the `ctx7` CLI to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service, including Flutter, Dart, Provider, sqflite, shared_preferences, file_picker, share_plus, or any other dependency.

Do not use it for refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

Steps:

1. Resolve the library:

   ```bash
   npx ctx7@latest library <name> "<user's full question>"
   ```

2. Pick the best `/org/project` match by exact name, description relevance, snippet count, source reputation, and benchmark score.
3. Fetch docs:

   ```bash
   npx ctx7@latest docs <libraryId> "<user's full question>"
   ```

Do not run more than 3 ctx7 commands per question. If ctx7 fails with a quota error, tell the user and suggest `npx ctx7@latest login` or setting `CONTEXT7_API_KEY`.

## Project Commands

- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Focused test: `flutter test test/path/to_test.dart`
- Run app: `flutter run`

## Working Rules

- Keep business rules in services, repositories, providers, or core utils. UI should call existing APIs instead of duplicating calculations.
- Add or update focused tests when changing reward, XP, recurrence, energy, inventory, migration, backup, or filtering behavior.
- Preserve user data semantics. Database migrations must be additive or explicitly migrate old data.
- Prefer existing `AppTheme` constants and shared widgets before adding new visual styles.
