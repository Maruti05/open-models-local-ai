---
name: flutter-code-standards
description: Use when writing or reviewing Flutter/Dart code to ensure compliance with Dart style guide, Flutter best practices, and project-specific conventions. Covers null safety, widget patterns, state management, and file organization.
---

# Flutter Code Standards

## Dart style (Effective Dart)
- `PascalCase` for types (classes, enums, typedefs, mixins)
- `lowerCamelCase` for constants, variables, methods, parameters
- `snake_case` for file names and library directives
- `SCREAMING_SNAKE_CASE` for static const that's not a collection

## Flutter-specific

### Widgets
- Prefer `StatelessWidget` unless state or lifecycle is needed
- Use `const` constructors on all widgets
- Extract widgets > 50 build lines into separate files
- Use `WidgetsBinding.instance.addPostFrameCallback` sparingly — prefer `WidgetsBindingObserver`
- Avoid `Builder` widgets unless necessary — use extracted methods/widgets

### State management (Provider-based)
```dart
// Registration
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyNotifier(service: _)),
  ],
  child: const MyApp(),
)

// Reading in widgets
final data = context.watch<MyNotifier>();  // rebuilds on change
context.read<MyNotifier>().doAction();      // no rebuild
```

### Asynchronous code
```dart
// Use Result pattern or try/catch at every async boundary
Future<Result<Data>> fetchData() async {
  try {
    final data = await repository.getData();
    return Result.success(data);
  } on Exception catch (e) {
    return Result.failure(e);
  }
}
```

### Controller lifecycle
```dart
class MyNotifier extends ChangeNotifier {
  late final TextEditingController _controller;

  MyNotifier() {
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Null safety
- All variables must be initialized or marked `late`
- Use `late final` for init-once fields (dependency injection, controllers)
- Never use `!` unless the preceding check guarantees non-null
- Prefer `?.` method calls and `??` defaults over `!`
