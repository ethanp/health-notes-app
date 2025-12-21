import 'package:flutter/cupertino.dart';
import 'package:health_notes/theme/app_theme.dart';

class VSpace {
  static const xs = SizedBox(height: AppSpacing.xs);
  static const s = SizedBox(height: AppSpacing.s);
  static const m = SizedBox(height: AppSpacing.m);
  static const l = SizedBox(height: AppSpacing.l);
  static const xl = SizedBox(height: AppSpacing.xl);
  static const xxl = SizedBox(height: AppSpacing.xxl);
  static SizedBox of(double height) => SizedBox(height: height);
}

class HSpace {
  static const xs = SizedBox(width: AppSpacing.xs);
  static const s = SizedBox(width: AppSpacing.s);
  static const m = SizedBox(width: AppSpacing.m);
  static const l = SizedBox(width: AppSpacing.l);
  static const xl = SizedBox(width: AppSpacing.xl);
  static const xxl = SizedBox(width: AppSpacing.xxl);
  static SizedBox of(double width) => SizedBox(width: width);
}
