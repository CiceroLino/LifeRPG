# Missions Search, Sort, and Skill Filter Design

## Context
The missions flow still has product TODOs in the app bar actions (`search`, `sort`, `skills filter`). Today these actions are placeholders and do not impact mission list behavior.

## Goals
- Implement mission search by title/description.
- Implement mission sorting from app bar menu options.
- Implement mission filtering by selected skills.
- Keep existing mission expansion/status/edit behavior intact.

## Non-goals
- Rewriting repository/database queries for filtered reads.
- Introducing server-side filtering.
- Changing mission persistence schema.

## UX Behavior
- Search action opens a mission search UI and updates mission results as user chooses a query.
- Sort action applies list ordering immediately.
- Skill filter action opens a multi-select skills modal and filters missions by selected skill ids.
- Empty search + no selected skills returns full mission list.

## Architecture
- Mission view state lives in `MissionProvider`:
  - `searchQuery`
  - `sortMode`
  - `selectedSkillIds`
- New derived list `filteredMissions` computes:
  1. search filter,
  2. skills filter,
  3. sort.
- `MissionsListScreen` consumes `filteredMissions`.
- `MainScreen` wires app bar callbacks to provider actions and filter/search modals.

## Data Flow
1. User triggers search/sort/skills filter from app bar.
2. `MainScreen` maps UI action to `MissionProvider` state updates.
3. `MissionProvider` recalculates `filteredMissions` in-memory.
4. `MissionsListScreen` rebuilds from provider notify cycle.

## Error Handling
- Provider keeps state changes defensive; invalid sort values fallback to default.
- UI shows lightweight feedback (`SnackBar`) when required context is unavailable.

## Testing
- Unit tests for provider filtering/sorting behavior.
- Widget tests for integration between screen actions and filtered results.

