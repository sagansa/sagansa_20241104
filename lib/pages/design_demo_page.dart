import 'package:flutter/material.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/app_spacing.dart';

class DesignDemoPage extends StatefulWidget {
  const DesignDemoPage({super.key});

  @override
  State<DesignDemoPage> createState() => _DesignDemoPageState();
}

class _DesignDemoPageState extends State<DesignDemoPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegant Design Demo'),
        actions: [
          const ThemeToggleButton(),
          AppSpacing.gapHorizontalSM,
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            AppSpacing.gapVerticalXL,
            _buildButtonSection(),
            AppSpacing.gapVerticalXL,
            _buildInputSection(),
            AppSpacing.gapVerticalXL,
            _buildCardSection(),
            AppSpacing.gapVerticalXL,
            _buildLoadingSection(),
            AppSpacing.gapVerticalXL,
            _buildListSection(),
          ],
        ),
      ),
      floatingActionButton: const ThemeToggleFAB(),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegant Black & White Design',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapVerticalSM,
        Text(
          'A sophisticated design system with clean aesthetics and smooth animations.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonSection() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegant Buttons',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapVerticalMD,
        ModernButton(
          text: 'Primary Button',
          onPressed: () => _showSnackBar('Primary button pressed'),
          icon: Icons.touch_app,
        ),
        AppSpacing.gapVerticalSM,
        ModernButton(
          text: 'Secondary Button',
          onPressed: () => _showSnackBar('Secondary button pressed'),
          icon: Icons.favorite_border,
        ),
        AppSpacing.gapVerticalSM,
        ModernButton(
          text: 'Action Button',
          onPressed: () => _showSnackBar('Action button pressed'),
          icon: Icons.text_fields,
        ),
        AppSpacing.gapVerticalSM,
        ModernButton(
          text: _isLoading ? 'Loading...' : 'Loading Button',
          isLoading: _isLoading,
          onPressed: () => _toggleLoading(),
          icon: Icons.refresh,
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegant Input Fields',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapVerticalMD,
        ModernTextField(
          labelText: 'Email Address',
          controller: _textController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.gapVerticalMD,
        ModernTextField(
          labelText: 'Password',
          controller: TextEditingController(),
          prefixIcon: Icons.lock_outlined,
          obscureText: true,
          suffixIcon: const Icon(Icons.visibility_outlined),
        ),
        AppSpacing.gapVerticalMD,
        ModernTextField(
          labelText: 'Message',
          controller: TextEditingController(),
          prefixIcon: Icons.message_outlined,
        ),
      ],
    );
  }

  Widget _buildCardSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegant Cards',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapVerticalMD,
        Card(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppSpacing.borderRadiusSM,
                      ),
                      child: Icon(
                        Icons.design_services,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    AppSpacing.gapHorizontalMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Design System',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Modern UI components',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapVerticalMD,
                Text(
                  'This elegant design system provides a consistent and beautiful user experience with smooth animations and clean aesthetics.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skeleton Loading States',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapVerticalMD,
        const SkeletonCard(height: 120),
        AppSpacing.gapVerticalSM,
        const SkeletonListItem(hasAvatar: true, hasTrailing: true),
        AppSpacing.gapVerticalSM,
        const SkeletonText(lines: 3),
      ],
    );
  }

  Widget _buildListSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegant List Items',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapVerticalMD,
        ...List.generate(3, (index) {
          final items = [
            {
              'icon': Icons.palette,
              'title': 'Color Palette',
              'subtitle': 'Black & white elegance'
            },
            {
              'icon': Icons.text_fields,
              'title': 'Typography',
              'subtitle': 'Clean and readable fonts'
            },
            {
              'icon': Icons.animation,
              'title': 'Animations',
              'subtitle': 'Smooth transitions'
            },
          ];
          final item = items[index];

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                item['title'] as String,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item['subtitle'] as String,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () => _showSnackBar('${item['title']} tapped'),
            ),
          );
        }),
      ],
    );
  }

  void _showSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSM,
        ),
      ),
    );
  }

  void _toggleLoading() {
    setState(() => _isLoading = !_isLoading);
    if (_isLoading) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
  }
}
