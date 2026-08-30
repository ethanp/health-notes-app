import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/screens/health_tool_category_form.dart';
import 'package:health_notes/screens/health_tool_category_screen.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/theme/spacing.dart';
import 'package:health_notes/widgets/health_notes_page.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class const MyToolsScreen() extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyToolsScreen> createState() => _MyToolsScreenState();
}

class _MyToolsScreenState() extends ConsumerState<MyToolsScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(healthToolCategoriesProvider);

    return HealthNotesPage(
      title: 'Tools',
      actions: [
        const CompactSyncStatusWidget(),
        IconButton(
          tooltip: 'Add category',
          onPressed: _showAddCategoryForm,
          icon: const Icon(Icons.add),
        ),
      ],
      body: categoriesAsync.when(
        data: (categories) =>
            categories.isEmpty ? emptyState() : categoriesList(categories),
        loading: () => const SyncStatusWidget.loading(
          message: 'Loading your health tools...',
        ),
        error: (error, stack) =>
            Center(child: Text('Error: $error', style: EText.error)),
      ),
    );
  }

  Widget emptyState() {
    return EEmptyState(
      title: 'No health tools yet',
      message: 'Create your first health tool category to get started',
      icon: Icons.handyman_outlined,
      action: FilledButton.icon(
        onPressed: _showAddCategoryForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget categoriesList(List<HealthToolCategory> categories) {
    return RefreshableListView<HealthToolCategory>(
      onReloadRequested: () async {
        await ref.read(healthToolCategoriesProvider.notifier).refresh();
      },
      items: categories,
      itemBuilder: (category) => categoryCard(category),
      padding: const EdgeInsets.all(AppSpacing.m),
    );
  }

  Widget categoryCard(HealthToolCategory category) {
    return ECard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.zero,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _navigateToCategory(category),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              categoryIcon(category),
              HSpace.m,
              Expanded(child: categoryDetails(category)),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorHex) {
    final parsed = int.tryParse(colorHex.replaceAll('#', '0xFF'));
    return parsed != null ? Color(parsed) : EColors.accent;
  }

  IconData _getIconData(String iconName) {
    return switch (iconName) {
      'allergies' => CupertinoIcons.circle,
      'anxiety' => CupertinoIcons.heart,
      'nausea' => CupertinoIcons.drop,
      'cold' => CupertinoIcons.snow,
      'flu' => CupertinoIcons.thermometer,
      'travel' => CupertinoIcons.airplane,
      'car_travel' => CupertinoIcons.car_detailed,
      'plane_travel' => CupertinoIcons.airplane,
      _ => CupertinoIcons.wrench,
    };
  }

  void _navigateToCategory(HealthToolCategory category) {
    context.push(HealthToolCategoryScreen(category: category));
  }

  void _showAddCategoryForm() {
    context.push(
      const HealthToolCategoryForm(
        title: 'Add Category',
        saveButtonText: 'Save',
      ),
    );
  }

  Widget categoryIcon(HealthToolCategory category) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _parseColor(category.colorHex),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Icon(
        _getIconData(category.iconName),
        color: CupertinoColors.white,
        size: 24,
      ),
    );
  }

  Widget categoryDetails(HealthToolCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.name, style: EText.label.large),
        VSpace.xs,
        Text(
          category.description,
          style: EText.body.medium.tertiary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
