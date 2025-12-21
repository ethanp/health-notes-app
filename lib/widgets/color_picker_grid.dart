import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

class ColorPickerGrid extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool useCircles;
  final double itemSize;
  final double spacing;

  const ColorPickerGrid({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.useCircles = true,
    this.itemSize = 40,
    this.spacing = 12,
  });

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
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemOrange,
    CupertinoColors.systemRed,
    CupertinoColors.systemPurple,
    CupertinoColors.systemPink,
    CupertinoColors.systemYellow,
    CupertinoColors.systemTeal,
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
          borderRadius: useCircles ? null : BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey4,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? AppComponents.mediumShadow : null,
        ),
        child: isSelected
            ? const Icon(
                CupertinoIcons.checkmark,
                color: CupertinoColors.white,
                size: 20,
              )
            : null,
      ),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return a.toARGB32() == b.toARGB32();
  }
}



