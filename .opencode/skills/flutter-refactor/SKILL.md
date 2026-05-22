---
name: flutter-refactor
description: Use when performing refactoring operations in Flutter code: renaming symbols, extracting widgets, reorganizing files, changing state management approach, or restructuring feature directories. Provides safe refactoring workflows with testing gates.
---

# Flutter Refactoring

This skill provides safe refactoring workflows for Flutter/Dart code.

## Pre-refactor checklist
1. Run `dart analyze` — note current warnings/errors
2. Run `flutter test` — ensure all tests pass
3. Load `.opencode/memory/conventions.md` — understand patterns
4. Load `.opencode/memory/decisions.md` — understand why current structure exists

## Safe refactoring patterns

### Renaming a symbol
1. Use Dart's built-in rename (IDE feature) or grep for all occurrences
2. Update imports in all affected files
3. Verify: `dart analyze` is clean

### Extracting a widget
1. Create new file `lib/feature/widgets/name.dart`
2. Copy build method content into new widget class
3. Pass required data as `final` constructor parameters
4. Replace original build content with `Name(data: ...)`
5. Verify: `dart analyze` is clean, widget test passes

### Changing state management
1. Create new provider/notifier alongside the old one (don't remove yet)
2. Update one widget at a time to use the new approach
3. After all consumers updated, remove old provider/notifier
4. Update `.opencode/memory/conventions.md` and `.opencode/memory/decisions.md`

## Post-refactor checklist
- [ ] `dart analyze` passes (no new issues vs pre-refactor)
- [ ] `flutter test` passes
- [ ] `.opencode/memory/` updated with any convention/decision changes
- [ ] No dead code left (unused imports, old implementations)
