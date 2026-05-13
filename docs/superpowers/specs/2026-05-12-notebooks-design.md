# Notebooks Design

## Goal

Add a local-first notes module named `Notebooks`, themed as handheld notebooks in the LifeRPG world. The first phase covers notebooks and notes only; PDF `Tomes` and media `Tavern` remain separate later phases.

## Product Shape

- `Notebooks` appears as a first-class navigation destination in the drawer and app bar navigation.
- A notebook has a name, optional description, active/archive state, creation time, and update time.
- A note belongs to one notebook and has title, body, creation time, and update time.
- Users can create, edit, archive, open, and search notebooks.
- Users can create, edit, delete, and search notes inside a notebook.
- Empty state starts clean: no seeded notebooks.

## Architecture

- SQLite tables: `notebooks` and `notes`.
- Data layer: `Notebook` and `Note` models plus `NotebookRepository`.
- State layer: `NotebookProvider` exposes notebooks, selected notes, search query, and CRUD actions.
- UI layer: `NotebooksScreen` lists notebooks; `NotebookDetailScreen` shows notes for one notebook; shared dialogs handle notebook/note editing.
- Backup/restore exports and restores both new tables.

## UX

The list should feel compact and useful, not like a marketing page. Cards show notebook name, description, note count, and updated date. Search is inline at the top of the Notebooks screen. Notes inside a notebook use a readable list and open in a dialog/sheet-style editor for quick capture.

## Testing

- Repository test covers CRUD, note counts, archive behavior, and backup/restore.
- Provider test covers loading, search filtering, and note CRUD.
- Widget smoke test covers empty state, create action visibility, and rendering a notebook.

