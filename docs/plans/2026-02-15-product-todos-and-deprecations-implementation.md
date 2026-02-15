# Product TODOs and Deprecations Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete remaining product TODOs and eliminate deprecated/lint issues while keeping current behavior stable.

**Architecture:** Extend existing providers and repositories for missing product actions; keep UI callbacks thin. Apply framework migrations in-place and verify with analyzer/tests.

**Tech Stack:** Flutter, Provider, sqflite, flutter_test.

---

### Task 1
Implement product TODOs in `MainScreen`, `MissionEditorScreen`, `SettingsProvider`, `PlayerStatsHeader`.

### Task 2
Implement DB reset operations and wire settings reset actions.

### Task 3
Migrate deprecated API usage and lint issues across UI files.

### Task 4
Run formatter, analyze, full test suite, and commit.
