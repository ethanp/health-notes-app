import 'package:flutter/material.dart';

class const ActivityChartMode({
  required final bool showCharts,
  required super.child,
}) extends InheritedWidget {
  static bool showChartsOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ActivityChartMode>()
            ?.showCharts ??
        false;
  }

  @override
  bool updateShouldNotify(ActivityChartMode oldWidget) =>
      showCharts != oldWidget.showCharts;
}

class const ActivityChartToggle({
  required final bool showCharts,
  required final ValueChanged<bool> onShowChartsChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: false, label: Text('Grid')),
        ButtonSegment(value: true, label: Text('Charts')),
      ],
      selected: {showCharts},
      onSelectionChanged: (selected) => onShowChartsChanged(selected.single),
    );
  }
}
