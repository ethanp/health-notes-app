String formatDecimalValue(double value) {
  if (value.isNaN || value.isInfinite) {
    return value.toString();
  }
  if (value.truncateToDouble() == value) {
    return value.toInt().toString();
  }

  final plain = value.toString();
  if (plain.contains('e') || plain.contains('E')) {
    final expanded = value.toStringAsFixed(10);
    return expanded.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return plain;
}
