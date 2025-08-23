import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color backgroundDepth5 = Color(0xFF1A1A1A);
  static const Color backgroundDepth4 = Color(0xFF251E1E);
  static const Color backgroundDepth3 = Color(0xFF2A2A2A);
  static const Color backgroundDepth2 = Color(0xFF404040);
  static const Color backgroundDepth1 = Color(0xFF505050);

  static const Color text1 = Color(0xFFFFFFFF);
  static const Color text2 = Color(0xFFE0E0E0);
  static const Color text3 = Color(0xFFB0B0B0);
  static const Color text4 = Color(0xFF808080);

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: backgroundDepth5,
    barBackgroundColor: backgroundDepth4,
    textTheme: CupertinoTextThemeData(
      primaryColor: CupertinoColors.systemBlue,
      textStyle: TextStyle(color: text1),
    ),
  );

  static BoxDecoration get filterContainer => BoxDecoration(
    color: backgroundDepth4,
    borderRadius: BorderRadius.circular(10),
  );

  static BoxDecoration filterContainerWithBorder(Color borderColor) =>
      BoxDecoration(
        color: backgroundDepth4,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
      );

  static BoxDecoration containerWithBorder({
    required Color backgroundColor,
    required Color borderColor,
    required double borderRadius,
  }) => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: borderColor, width: 1),
  );

  static BoxDecoration get datePickerContainer => containerWithBorder(
    backgroundColor: backgroundDepth4,
    borderColor: CupertinoColors.systemBlue.withOpacity(0.4),
    borderRadius: 12,
  );

  static BoxDecoration get inputContainer => containerWithBorder(
    backgroundColor: backgroundDepth3,
    borderColor: backgroundDepth2,
    borderRadius: 10,
  );

  static BoxDecoration get cardContainer => containerWithBorder(
    backgroundColor: backgroundDepth5,
    borderColor: backgroundDepth2,
    borderRadius: 8,
  );

  static BoxDecoration get deleteContainer => BoxDecoration(
    color: CupertinoColors.destructiveRed,
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration get labelContainer => containerWithBorder(
    backgroundColor: backgroundDepth3,
    borderColor: backgroundDepth2,
    borderRadius: 6,
  );

  static TextStyle textStyle(
    double fontSize,
    FontWeight fontWeight,
    Color color,
  ) => TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);

  static TextStyle titleStyle(double fontSize) =>
      textStyle(fontSize, FontWeight.w600, text1);

  static TextStyle bodyStyle(double fontSize) =>
      textStyle(fontSize, FontWeight.normal, text1);

  static TextStyle labelStyle(double fontSize, FontWeight fontWeight) =>
      textStyle(fontSize, fontWeight, text1);

  static TextStyle statusStyle(double fontSize, Color color) =>
      textStyle(fontSize, FontWeight.normal, color);

  static TextStyle buttonStyle(double fontSize, Color color) =>
      textStyle(fontSize, FontWeight.w600, color);

  static TextStyle get titleLarge => titleStyle(32);
  static TextStyle get titleMedium => titleStyle(16);
  static TextStyle get titleSmall => titleStyle(14);

  static TextStyle get bodyLarge => bodyStyle(16);
  static TextStyle get bodyMedium => bodyStyle(14);
  static TextStyle get bodySmall => bodyStyle(12);

  static TextStyle get labelMedium => labelStyle(14, FontWeight.w500);
  static TextStyle get labelSmall => labelStyle(12, FontWeight.w500);

  static TextStyle get caption => statusStyle(12, text3);
  static TextStyle get captionSecondary => statusStyle(12, text4);
  static TextStyle get subtitle => statusStyle(16, text2);

  static TextStyle get button => buttonStyle(16, CupertinoColors.white);
  static TextStyle get buttonSecondary =>
      buttonStyle(16, CupertinoColors.systemBlue);

  static TextStyle get input => bodyStyle(16);
  static TextStyle get inputPlaceholder => statusStyle(16, text4);

  static TextStyle get error => statusStyle(14, CupertinoColors.destructiveRed);
}
