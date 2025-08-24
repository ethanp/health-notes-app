# Development Standards

## Code Style Preferences

### Widget Method Naming (IMPORTANT)
- **Widget Helper Methods**: Do NOT use underscore prefixes for helper methods within widget classes
- **Private Methods**: Only use underscore prefixes for methods in helper classes that should not be seen through the interface
- **Rationale**: Widgets are typically self-contained and don't have external interfaces to protect
- **Enforcement**: This rule applies to ALL widget classes (StatelessWidget, StatefulWidget, ConsumerWidget, etc.)

### Widget Constructor Keys (IMPORTANT)
- **Omit `key` parameter**: Do NOT include `super.key` in widget constructors unless the key is actually used in the file
- **Rationale**: Most widgets don't need keys, and omitting them makes code cleaner
- **Exception**: Only include `key` when it's passed to child widgets or used for widget identification

### Examples
```dart
// ✅ Preferred in widget classes
class MyWidget extends StatelessWidget {
  const MyWidget(); // No key needed
  
  void saveNote() { ... }
  Widget buildDrugDoseItem() { ... }
  void showAddNoteModal() { ... }
  void navigateToEdit() { ... }
  Widget buildDateTimeSection() { ... }
}

// ❌ Avoid in widget classes
class MyWidget extends StatelessWidget {
  const MyWidget({super.key}); // Unnecessary key
  
  void _saveNote() { ... }
  Widget _buildDrugDoseItem() { ... }
  void _showAddNoteModal() { ... }
  void _navigateToEdit() { ... }
  Widget _buildDateTimeSection() { ... }
}

// ✅ Use underscores for truly private methods in helper classes
class _HelperClass {
  void _internalMethod() { ... } // Should not be exposed
}

// ✅ Include key only when actually used
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      key: key, // Key is actually used
      child: Text('Hello'),
    );
  }
}
```

### Color Constants
- Use numerical depth scale naming:
  - Backgrounds: `backgroundDepth1` (lightest) through `backgroundDepth5` (darkest)
  - Borders: `borderDepth1` through `borderDepth5`
  - Text colors: `textColor1` through `textColor4`

### Comments
- Prefer minimal explanatory comments
- Remove obvious comments like "// Provider for current user"

### State Management
- Use Riverpod 3.0 with generic `Ref` type instead of deprecated provider-specific Ref types

### Secrets Management
- Keep secrets in `.env` file to keep them out of git
- Apply this convention for all future secrets

### Generated Files
- `.gitignore` should exclude `*.g.dart` and `*.freezed.dart` files

### Deprecated Methods
- **Avoid deprecated methods**: Use `flutter analyze` regularly to catch deprecated method usage
- **Color opacity**: Use `color.withValues(alpha: 0.5)` instead of `color.withOpacity(0.5)`
- **Stay updated**: Keep dependencies updated and follow migration guides for breaking changes
- **Check linter warnings**: Address all linter warnings, especially deprecation warnings

### Code Quality Tools
- **Run analysis**: Use `flutter analyze` before committing to catch issues early
- **Run tests**: Use `flutter test` to ensure functionality works correctly
- **Format code**: Use `dart format` or `flutter format` to maintain consistent code style
- **Fix issues**: Address all linter warnings and errors before merging code

### Code Style Preferences
- **Functional programming**: Prefer functional one-liner style over imperative code
- **DRY principle**: Eliminate code duplication through shared methods and utilities
- **Idiomatic Dart**: Use Dart's built-in functional features (map, where, join, etc.)
- **Clean chains**: Prefer method chaining over multiple statements
- **Concise code**: Aim for readable, minimal code that expresses intent clearly
- **Late final fields**: Use `late final` for fields initialized in `initState()` with functional transformations
- **Clear branching**: Use explicit if/else branches instead of multiple ternary expressions for better readability

#### Late Final Pattern
Use `late final` for fields that need to be initialized in `initState()` with functional data transformations:

```dart
// ✅ Preferred - late final with functional initialization
class _MyWidgetState extends ConsumerState<MyWidget> {
  late final Map<int, Controller> _controllers;
  late final List<String> _processedItems;
  
  @override
  void initState() {
    super.initState();
    
    // Functional initialization - immutable reference after creation
    _controllers = items.asMap().map(
      (key, value) => MapEntry(key, Controller(value)),
    );
    
    _processedItems = rawItems
        .where((item) => item.isValid)
        .map((item) => item.process())
        .toList();
  }
}

// ❌ Avoid - mutable fields or early initialization
class _MyWidgetState extends ConsumerState<MyWidget> {
  final Map<int, Controller> _controllers = {}; // Empty initialization
  Map<int, Controller> _controllers2 = {}; // Mutable reference
}
```

**Benefits:**
- **Immutable reference**: Cannot be reassigned after initialization
- **Lazy initialization**: Only initialized when needed in `initState()`
- **Type safety**: Dart ensures field is initialized before use
- **Functional style**: Enables clean functional transformations

#### Clear Branching Pattern
Use explicit if/else branches instead of multiple ternary expressions for better readability:

```dart
// ✅ Preferred - Clear branching logic
@override
void initState() {
  super.initState();
  
  if (widget.item != null) {
    // Editing existing item
    final item = widget.item!;
    _nameController = TextEditingController(text: item.name);
    _descriptionController = TextEditingController(text: item.description);
    _selectedDate = item.date;
    _tags = List.from(item.tags);
  } else {
    // Creating new item
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();
    _tags = <String>[];
  }
}

// ❌ Avoid - Multiple ternary expressions
@override
void initState() {
  super.initState();
  _nameController = TextEditingController(text: widget.item?.name ?? '');
  _descriptionController = TextEditingController(text: widget.item?.description ?? '');
  _selectedDate = widget.item?.date ?? DateTime.now();
  _tags = widget.item != null ? List.from(widget.item!.tags) : <String>[];
}
```

#### Examples
```dart
// ✅ Preferred - Functional one-liner
return [item1, item2, ...items.map((i) => i.name)]
    .where((text) => text.isNotEmpty)
    .join(' ');

// ❌ Avoid - Imperative style
final parts = <String>[];
if (item1.isNotEmpty) parts.add(item1);
if (item2.isNotEmpty) parts.add(item2);
for (final item in items) {
  if (item.name.isNotEmpty) parts.add(item.name);
}
return parts.join(' ');
```

#### Loop Conversion Patterns
```dart
// ✅ Preferred - Functional one-liners for loops
// Converting indexed loops to functional style with late final
late final Map<int, DrugDoseControllers> _drugDoseControllers;

// In initState():
_drugDoseControllers = _drugDoses.asMap().map(
  (key, value) => MapEntry(key, DrugDoseControllers(value)),
);

// Converting nested loops to functional style
return notes
    .expand((note) => note.drugDoses)
    .map((dose) => dose.name)
    .where((name) => name.isNotEmpty)
    .toSet()
    .toList()
  ..sort();

// ✅ Preferred - Use forEach for side effects (disposal, etc.)
_drugDoseControllers.values.forEach((controllers) => controllers.dispose());

// ❌ Avoid - map().toList() when return value is unused
_drugDoseControllers.values.map((controllers) => controllers.dispose()).toList();

// ❌ Avoid - Imperative loops and mutable fields
final Map<int, DrugDoseControllers> _drugDoseControllers = {};
for (int i = 0; i < _drugDoses.length; i++) {
  _drugDoseControllers[i] = DrugDoseControllers(_drugDoses[i]);
}

for (final note in notes) {
  for (final dose in note.drugDoses) {
    if (dose.name.isNotEmpty) {
      drugs.add(dose.name);
    }
  }
}

for (final controllers in _drugDoseControllers.values) {
  controllers.dispose();
}
```
