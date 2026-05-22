# Project Conventions

## Architecture
- Feature-first: each feature in `lib/features/<name>/`
- Shared code in `lib/core/` (theme, constants, utils, extensions)

## State Management
- Provider with ChangeNotifier
- Notifiers in `lib/features/<name>/controllers/`
- Services/repositories in `lib/features/<name>/services/`
- Models in `lib/features/<name>/models/`

## Widgets
- One widget class per file
- Extract widget into own file when build() > 50 lines
- Screens go in `lib/features/<name>/views/`

## Testing
- One test file per source file
- Unit tests in `test/features/<name>/`
- Widget tests mirror the lib structure
