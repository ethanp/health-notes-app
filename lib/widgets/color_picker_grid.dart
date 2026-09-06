import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:health_notes/theme/app_theme.dart';

class const ColorPickerGrid({
  required final List<Color> colors,
  required final Color selectedColor,
  required final ValueChanged<Color> onColorSelected,
  final bool useCircles = true,
  final double itemSize = 40,
  final double spacing = 12,
}) extends StatelessWidget {
  static List<Color> get defaultColors => const [
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFFFFF176),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFF9575CD),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
  ];

  static List<Color> get systemColors => const [
    EColors.accent,
    EColors.success,
    EColors.warning,
    EColors.danger,
    Color(0xFFAF52DE),
    Color(0xFFFF2D55),
    Color(0xFFFFCC00),
    Color(0xFF5AC8FA),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: colors.map((color) => _colorOption(color)).toList(),
    );
  }

  Widget _colorOption(Color color) {
    final isSelected = _colorsMatch(selectedColor, color);

    return GestureDetector(
      onTap: () => onColorSelected(color),
      child: Container(
        width: itemSize,
        height: itemSize,
        decoration: BoxDecoration(
          color: color,
          shape: useCircles ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: useCircles
              ? null
              : BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected ? Colors.white : EColors.surfaceRaised,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? AppComponents.mediumShadow : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return a.toARGB32() == b.toARGB32();
  }
}
