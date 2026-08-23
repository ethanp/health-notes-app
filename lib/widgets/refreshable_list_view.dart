import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/theme/app_theme.dart';

class RefreshableListView<T> extends ConsumerWidget {
  final Future<void> Function() onReloadRequested;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;

  const RefreshableListView({
    required this.onReloadRequested,
    required this.items,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(AppSpacing.m),
    this.controller,
    this.primary = true,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      controller: controller,
      primary: primary,
      physics: physics,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onReloadRequested),
        if (padding != null)
          SliverPadding(padding: padding!, sliver: sliverList())
        else
          sliverList(),
      ],
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
