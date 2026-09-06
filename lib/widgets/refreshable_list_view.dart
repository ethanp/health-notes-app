import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/theme/app_theme.dart';

class const RefreshableListView<T>({
  required final Future<void> Function() onReloadRequested,
  required final List<T> items,
  required final Widget Function(T) itemBuilder,
  final EdgeInsetsGeometry? padding = const EdgeInsets.all(AppSpacing.m),
  final ScrollController? controller,
  final bool? primary = true,
  final ScrollPhysics? physics = const AlwaysScrollableScrollPhysics(),
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onReloadRequested,
      child: CustomScrollView(
        controller: controller,
        primary: primary,
        physics: physics,
        slivers: [
          if (padding != null)
            SliverPadding(padding: padding!, sliver: sliverList())
          else
            sliverList(),
        ],
      ),
    );
  }

  Widget sliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => itemBuilder(items[index]),
        childCount: items.length,
      ),
    );
  }
}
