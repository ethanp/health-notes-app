import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/providers/conditions_provider.dart';
import 'package:health_notes/screens/condition_detail_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';

class ConditionBadge extends ConsumerWidget {
  final String conditionId;

  const ConditionBadge({super.key, required this.conditionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(conditionsNotifierProvider);

    return conditionsAsync.when(
      data: (conditions) {
        final condition = conditions
            .where((c) => c.id == conditionId)
            .firstOrNull;
        if (condition == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () =>
              context.push(ConditionDetailScreen(conditionId: conditionId)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: AppComponents.tintedSolidDecoration(
              condition.color,
              radius: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(condition.icon, size: 12, color: condition.color),
                HSpace.xs,
                Text(
                  condition.name,
                  style: AppText.caption.copyWith(color: condition.color),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
