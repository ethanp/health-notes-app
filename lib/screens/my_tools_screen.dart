import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/screens/health_tool_category_form.dart';
import 'package:health_notes/screens/health_tool_category_screen.dart';
import 'package:health_notes/theme/app_theme.dart';

import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';
import 'package:health_notes/widgets/sync_status_widget.dart';

class MyToolsScreen extends ConsumerStatefulWidget {
  const MyToolsScreen();

  @override
  ConsumerState<MyToolsScreen> createState() => _MyToolsScreenState();
}

class _MyToolsScreenState extends ConsumerState<MyToolsScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(healthToolCategoriesNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: EnhancedUIComponents.navigationBar(
        title: 'My Tools',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => AuthUtils.showSignOutDialog(context),
          child: const Icon(CupertinoIcons.person_circle),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddCategoryForm(),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: categoriesAsync.when(
          data: (categories) =>
              categories.isEmpty ? emptyState() : categoriesList(categories),
          loading: () => const SyncStatusWidget.loading(
            message: 'Loading your health tools...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTypography.error)),
        ),
      ),
    );
  }

  Widget emptyState() {
    return EnhancedUIComponents.emptyState(
      title: 'No health tools yet',
      message: 'Create your first health tool category to get started',
      icon: CupertinoIcons.wrench,
      action: EnhancedUIComponents.button(
        text: 'Add Category',
        onPressed: () => _showAddCategoryForm(),
        icon: CupertinoIcons.add,
      ),
    );
  }

  Widget categoriesList(List<HealthToolCategory> categories) {
    return RefreshableListView<HealthToolCategory>(
      onRefresh: () async {
        await ref.read(healthToolCategoriesNotifierProvider.notifier).refresh();
      },
      items: categories,
      itemBuilder: (category) => categoryCard(category),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget categoryCard(HealthToolCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppComponents.primaryCard,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _navigateToCategory(category),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              categoryIcon(category),
              const SizedBox(width: 16),
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
    return parsed != null ? Color(parsed) : AppColors.primary;
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
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => HealthToolCategoryScreen(category: category),
      ),
    );
  }

  void _showAddCategoryForm() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const HealthToolCategoryForm(
          title: 'Add Category',
          saveButtonText: 'Save',
        ),
      ),
    );
  }

  Widget categoryIcon(HealthToolCategory category) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _parseColor(category.colorHex),
        borderRadius: BorderRadius.circular(12),
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
        Text(category.name, style: AppTypography.labelLarge),
        const SizedBox(height: 4),
        Text(
          category.description,
          style: AppTypography.bodyMediumTertiary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
