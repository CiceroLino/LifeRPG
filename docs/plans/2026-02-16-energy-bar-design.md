# Energy Bar Dual Mode Design

**Date:** 2026-02-16

## Goal
Implement two user-selectable energy behaviors in settings:
- Manual mode: user controls current energy by interacting with the bar.
- Automatic mode: energy follows time schedule (wake/sleep), draining while awake and charging while asleep.

## Requirements Confirmed
- Mode selector in settings: Manual vs Automatic.
- Automatic mode uses wake and sleep times.
- On wake time, energy is full.
- During awake period, energy drains from 100% to 0% linearly.
- During sleep period, energy charges from 0% to 100% linearly.
- In automatic mode, manual clicks on energy bar are blocked.
- Sleep phase color shifts from red toward cyan.
- Auto refresh cadence: once per minute.

## Existing State (Current Code)
- Data model and DB already include `current_energy`, `energy_mode`, `wake_up_time`, `sleep_time`.
- Header already renders timer text for auto mode but uses stored `currentEnergy` for progress and has no schedule configuration UI.
- Settings screen currently has no controls for energy mode/schedule.

## Proposed Architecture
- Persist mode and schedule in `player` record via `PlayerProvider`/`PlayerRepository`.
- Keep manual mode persisted in DB (`current_energy`).
- In auto mode, compute energy dynamically from current time + schedule at render time (no periodic DB writes).
- Trigger UI repaint every minute from `MainScreen` when mode is auto.

## Business Rules
1. `manual`
- Bar interaction enabled.
- User-adjusted value clamped to 0..100.
- Saved into `player.current_energy`.

2. `auto`
- Bar interaction disabled.
- Schedule required (`wake_up_time`, `sleep_time`).
- If schedule invalid/missing, show "set schedule" state.
- If `wake == sleep`, reject with validation error.

3. Time-cycle behavior
- Awake window (`wake -> sleep`): 100 -> 0.
- Sleep window (`sleep -> wake next day`): 0 -> 100.
- Works for both same-day and midnight-crossing schedules.

## UI/UX
- Settings screen adds:
- Energy mode selector.
- Wake up time picker.
- Sleep time picker.
- Time pickers visible/enabled only when mode is auto.
- Header energy bar:
- Manual: current behavior + interactive adjustment.
- Auto awake: red depletion bar.
- Auto sleep: color interpolates red -> cyan while charging.

## Testing Strategy
- Unit tests for schedule-based energy computation:
- awake drain
- sleep charge
- midnight crossing
- bounds 0..100
- Widget test for settings:
- toggling mode and showing/hiding schedule fields
- saving mode/schedule
- Widget test for header:
- manual interaction enabled only in manual mode
- auto mode non-interactive
- sleep phase color interpolation toward cyan

## Non-goals
- Background service/job for energy updates.
- Continuous second-level animation updates.
- New persistence table.
