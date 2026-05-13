# Notebooks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first-phase `Notebooks` feature as a local-first notebook and notes library.

**Architecture:** Add `notebooks` and `notes` tables to SQLite version 11, expose typed models/repository/provider, then add screens into the existing drawer/app-bar navigation. Backup/restore includes the new tables so user notes remain portable.

**Tech Stack:** Flutter, Provider, sqflite/sqflite_common_ffi, existing AppTheme and AppLocalizations.

---

### Task 1: Data Layer

**Files:**
- Create: `lib/data/models/notebook.dart`
- Create: `lib/data/models/note.dart`
- Create: `lib/data/repositories/notebook_repository.dart`
- Modify: `lib/data/database/database_helper.dart`
- Test: `test/data/repositories/notebook_repository_test.dart`

- [ ] Write repository tests for notebook/note CRUD, archive behavior, note counts, and backup/restore.
- [ ] Add model classes with `toMap`, `fromMap`, and `copyWith`.
- [ ] Add database migration version 11 and backup/restore table handling.
- [ ] Implement `NotebookRepository`.
- [ ] Run `flutter test test/data/repositories/notebook_repository_test.dart`.

### Task 2: Provider

**Files:**
- Create: `lib/providers/notebook_provider.dart`
- Test: `test/providers/notebook_provider_test.dart`

- [ ] Write provider tests for loading, search, notebook creation, note creation/update/delete.
- [ ] Implement provider with loading state, search query, selected notebook notes, and CRUD.
- [ ] Run `flutter test test/providers/notebook_provider_test.dart`.

### Task 3: UI and Navigation

**Files:**
- Create: `lib/ui/screens/notebooks/notebooks_screen.dart`
- Create: `lib/ui/screens/notebooks/notebook_detail_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/ui/screens/main_screen.dart`
- Modify: `lib/ui/widgets/common/app_drawer.dart`
- Modify: `lib/ui/widgets/common/liferpg_app_bar.dart`
- Modify: `lib/l10n/app_localizations.dart`
- Test: `test/ui/screens/notebooks/notebooks_screen_test.dart`

- [ ] Write widget smoke tests for empty state and rendering a notebook.
- [ ] Add localized strings for English, Portuguese, and Spanish.
- [ ] Add provider registration.
- [ ] Add Notebooks route to drawer, app bar navigation, and main IndexedStack.
- [ ] Implement screens and dialogs.
- [ ] Run `flutter test test/ui/screens/notebooks/notebooks_screen_test.dart`.

### Task 4: Verification

**Files:**
- Modify: `docs/project-guide.md`

- [ ] Document Notebooks in the project guide.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter build linux --debug`.

