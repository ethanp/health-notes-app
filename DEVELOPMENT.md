# Development Standards

## Code Style Preferences

### Method Naming
- **Widget Helper Methods**: Do NOT use underscore prefixes for helper methods within widgets
- **Private Methods**: Only use underscore prefixes for methods in helper classes that should not be seen through the interface
- **Rationale**: Widgets are typically self-contained and don't have external interfaces to protect

### Examples
```dart
// ✅ Preferred in widgets
void saveNote() { ... }
Widget buildDrugDoseItem() { ... }
void showAddNoteModal() { ... }

// ❌ Avoid in widgets
void _saveNote() { ... }
Widget _buildDrugDoseItem() { ... }
void _showAddNoteModal() { ... }

// ✅ Use underscores for truly private methods in helper classes
class _HelperClass {
  void _internalMethod() { ... } // Should not be exposed
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
