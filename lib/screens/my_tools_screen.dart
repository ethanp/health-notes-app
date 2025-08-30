import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_notes/models/health_tool_category.dart';
import 'package:health_notes/providers/health_tools_provider.dart';
import 'package:health_notes/screens/health_tool_category_screen.dart';
import 'package:health_notes/screens/health_tool_category_form.dart';
import 'package:health_notes/theme/app_theme.dart';
import 'package:health_notes/utils/auth_utils.dart';
import 'package:health_notes/widgets/enhanced_ui_components.dart';
import 'package:health_notes/widgets/refreshable_list_view.dart';

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
      navigationBar: EnhancedUIComponents.enhancedNavigationBar(
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
          data: (categories) => categories.isEmpty
              ? buildEmptyState()
              : buildCategoriesList(categories),
          loading: () => EnhancedUIComponents.enhancedLoadingIndicator(
            message: 'Loading your health tools...',
          ),
          error: (error, stack) =>
              Center(child: Text('Error: $error', style: AppTheme.error)),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return EnhancedUIComponents.enhancedEmptyState(
      title: 'No health tools yet',
      message: 'Create your first health tool category to get started',
      icon: CupertinoIcons.wrench,
      action: EnhancedUIComponents.enhancedButton(
        text: 'Add Category',
        onPressed: () => _showAddCategoryForm(),
        icon: CupertinoIcons.add,
      ),
    );
  }

  Widget buildCategoriesList(List<HealthToolCategory> categories) {
    return RefreshableListView<HealthToolCategory>(
      onRefresh: () async {
        await ref.read(healthToolCategoriesNotifierProvider.notifier).refresh();
      },
      items: categories,
      itemBuilder: (category) => buildCategoryCard(category),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget buildCategoryCard(HealthToolCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.primaryCard,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _navigateToCategory(category),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: AppTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppTheme.primary;
    }
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
}
