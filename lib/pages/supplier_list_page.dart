import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../models/supplier_model.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';
import '../widgets/add_fab.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_app_bar_action.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/search_app_bar_action.dart';
import '../widgets/status_badge.dart';
import 'supplier_detail_page.dart';
import 'supplier_form_page.dart';

class SupplierListPage extends StatelessWidget {
  const SupplierListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupplierProvider(),
      child: const _SupplierListScaffold(),
    );
  }
}

class _SupplierListScaffold extends StatelessWidget {
  const _SupplierListScaffold();

  void _openDetail(BuildContext context, SupplierModel supplier) async {
    final provider = context.read<SupplierProvider>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SupplierDetailPage(supplierId: supplier.id)),
    );
    if (result == true) provider.loadInitialSuppliers();
  }

  void _openForm(BuildContext context, {SupplierModel? supplier}) async {
    final provider = context.read<SupplierProvider>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormPage(supplier: supplier)),
    );
    if (result == true) provider.loadInitialSuppliers();
  }

  String _mediaUrl(String imagePath) {
    return '${ApiConstants.baseUrl}/media/$imagePath';
  }

  StatusType _statusType(int status) {
    switch (status) {
      case 2:
        return StatusType.success;
      case 3:
        return StatusType.error;
      default:
        return StatusType.warning;
    }
  }

  void _openFilterSheet(BuildContext context) {
    final provider = context.read<SupplierProvider>();
    FilterBottomSheet.show(
      context,
      title: 'Filter Status',
      fields: [
        DropdownFilterField<int?>(
          label: 'Status',
          value: provider.list.selectedStatus,
          options: const [
            (null, 'Semua'),
            (1, 'Belum Diperiksa'),
            (2, 'Valid'),
            (3, 'Blacklist'),
          ],
        ),
      ],
      onApply: (values) {
        provider.setStatusFilter(values['Status'] as int?);
      },
      onReset: () {
        provider.setStatusFilter(null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<SupplierProvider>();
    final list = provider.list;
    final canManage =
        context.read<AuthProvider>().hasAnyRole(['admin', 'super_admin', 'supervisor']);

    return Scaffold(
      appBar: AppBar(
        title: list.isSearchVisible ? null : const Text('Supplier'),
        bottom: list.isSearchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari nama, bank, no rekening...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: list.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => provider.clearSearch(),
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (v) => provider.setSearchQuery(v),
                  ),
                ),
              )
            : null,
        actions: [
          if (!list.isSearchVisible)
            SearchAppBarAction(
              isSearchActive: false,
              onTap: () => provider.setSearchVisible(true),
            ),
          if (list.isSearchVisible)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => provider.closeSearch(),
            ),
          FilterAppBarAction(
            activeCount: list.activeFilterCount,
            onTap: () => _openFilterSheet(context),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? AddFab(onPressed: () => _openForm(context))
          : null,
      body: list.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.errorMessage != null
              ? _buildError(context, colorScheme, list.errorMessage!)
              : !list.hasSearched
                  ? _buildPromptSearch(colorScheme)
                  : list.suppliers.isEmpty
                      ? _buildEmpty(colorScheme)
                      : _buildList(context, list, colorScheme, textTheme),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, SupplierListState list,
      ColorScheme colorScheme, TextTheme textTheme) {
    final provider = context.read<SupplierProvider>();
    return RefreshIndicator(
      onRefresh: provider.loadInitialSuppliers,
      child: ListView.builder(
        controller: provider.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: list.suppliers.length + (list.hasMore ? 1 : 0),
        itemBuilder: (context, idx) {
          if (idx == list.suppliers.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildSupplierCard(
              context, list.suppliers[idx], colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildSupplierCard(BuildContext context, SupplierModel s,
      ColorScheme colorScheme, TextTheme textTheme) {
    final statusType = _statusType(s.status);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLG,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusLG,
        onTap: () => _openDetail(context, s),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.borderRadiusSM,
                  color: colorScheme.primaryContainer,
                ),
                clipBehavior: Clip.antiAlias,
                child: s.image != null && s.image!.isNotEmpty
                    ? Image.network(
                        _mediaUrl(s.image!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAvatarFallback(s, colorScheme),
                      )
                    : _buildAvatarFallback(s, colorScheme),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.gapHorizontalSM,
                        StatusBadge(
                          label: s.statusText,
                          type: statusType,
                        ),
                      ],
                    ),
                    if (s.bankName != null || s.bankAccountNo != null) ...[
                      AppSpacing.gapVerticalXS,
                      Row(
                        children: [
                          Icon(Icons.account_balance_rounded,
                              size: 13,
                              color: AppColors.info),
                          AppSpacing.gapHorizontalXS,
                          Expanded(
                            child: Text(
                              [
                                if (s.bankName != null) s.bankName!,
                                if (s.bankAccountNo != null)
                                  s.bankAccountNo!,
                              ].join(' · '),
                              style: textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (s.cityName != null) ...[
                      AppSpacing.gapHorizontalXS,
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13,
                              color: AppColors.info),
                          AppSpacing.gapHorizontalXS,
                          Expanded(
                            child: Text(
                              s.cityName!,
                              style: textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapHorizontalSM,
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.info),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(SupplierModel s, ColorScheme colorScheme) {
    return Center(
      child: Text(
        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPromptSearch(ColorScheme colorScheme) {
    return EmptyState(
      icon: Icons.search_rounded,
      title: 'Cari supplier menggunakan ikon search\ndi pojok kanan atas.',
    );
  }

  Widget _buildError(
      BuildContext context, ColorScheme colorScheme, String message) {
    final provider = context.read<SupplierProvider>();
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: message,
      subtitle: 'Terjadi kesalahan saat memuat data',
      action: ElevatedButton.icon(
        onPressed: provider.loadInitialSuppliers,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba Lagi'),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return EmptyState(
      icon: Icons.store_mall_directory_outlined,
      title: 'Tidak ada supplier yang sesuai.',
    );
  }
}
