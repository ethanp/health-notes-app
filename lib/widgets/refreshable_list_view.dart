import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RefreshableListView<T> extends ConsumerWidget {
  final Future<void> Function() onRefresh;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;

  const RefreshableListView({
    required this.onRefresh,
    required this.items,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
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
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        if (padding != null)
          SliverPadding(padding: padding!, sliver: _buildSliverList())
        else
          _buildSliverList(),
      ],
    );
  }

  Widget _buildSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => itemBuilder(items[index]),
        childCount: items.length,
      ),
    );
  }
}
