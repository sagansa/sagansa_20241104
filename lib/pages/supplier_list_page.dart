import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../models/supplier_model.dart';
import '../providers/auth_provider.dart';
import '../services/supplier_service.dart';
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

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  final SupplierService _service = SupplierService();
  final ScrollController _scrollController = ScrollController();

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasSearched = false;
  bool _canManage = false;
  bool _searchVisible = false;
  String? _errorMessage;
  int? _selectedStatus;
  int _page = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _loadUser() {
    _canManage = context.read<AuthProvider>().hasAnyRole(['admin', 'super_admin', 'supervisor']);
  }

  Future<void> _fetchSuppliers() async {
    final query = _searchQuery;
    if (query.isEmpty && _selectedStatus == null) {
      setState(() {
        _suppliers = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _suppliers = [];
      _hasMore = true;
    });
    try {
      final result = await _service.getSuppliersPaged(
        page: _page,
        search: query.isEmpty ? null : query,
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _suppliers = result['data'] as List<SupplierModel>;
        _hasMore = result['has_more'] as bool;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final query = _searchQuery;
      final result = await _service.getSuppliersPaged(
        page: _page + 1,
        search: query.isEmpty ? null : query,
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _suppliers.addAll(result['data'] as List<SupplierModel>);
        _hasMore = result['has_more'] as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
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

  void _openDetail(SupplierModel supplier) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SupplierDetailPage(supplierId: supplier.id)),
    );
    if (result == true) _fetchSuppliers();
  }

  void _openForm({SupplierModel? supplier}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormPage(supplier: supplier)),
    );
    if (result == true) _fetchSuppliers();
  }

  String _mediaUrl(String imagePath) {
    return '${ApiConstants.baseUrl}/media/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible ? null : const Text('Supplier'),
        bottom: _searchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Cari nama, bank, no rekening...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _hasSearched = false;
                                  _suppliers = [];
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (v) {
                      setState(() => _searchQuery = v);
                      if (v.length >= 3 || v.isEmpty) {
                        _fetchSuppliers();
                      }
                    },
                  ),
                ),
              )
            : null,
        actions: [
          if (!_searchVisible)
            SearchAppBarAction(
              isSearchActive: false,
              onTap: () => setState(() => _searchVisible = true),
            ),
          if (_searchVisible)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() {
                _searchVisible = false;
                _searchQuery = '';
                _hasSearched = false;
                _suppliers = [];
              }),
            ),
          FilterAppBarAction(
            activeCount: _activeFilterCount,
            onTap: _openFilterSheet,
          ),
        ],
      ),
      floatingActionButton: _canManage
          ? AddFab(onPressed: () => _openForm())
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError(colorScheme, textTheme)
              : !_hasSearched
                  ? _buildPromptSearch(colorScheme)
                  : _suppliers.isEmpty
                      ? _buildEmpty(colorScheme)
                      : _buildList(colorScheme, textTheme),
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

  int get _activeFilterCount => _selectedStatus != null ? 1 : 0;
  void _openFilterSheet() {
    FilterBottomSheet.show(
      context,
      title: 'Filter Status',
      fields: [
        DropdownFilterField<int?>(
          label: 'Status',
          value: _selectedStatus,
          options: const [
            (null, 'Semua'),
            (1, 'Belum Diperiksa'),
            (2, 'Valid'),
            (3, 'Blacklist'),
          ],
        ),
      ],
      onApply: (values) {
        setState(() {
          _selectedStatus = values['Status'] as int?;
        });
        _fetchSuppliers();
      },
      onReset: () {
        setState(() => _selectedStatus = null);
        _fetchSuppliers();
      },
    );
  }

  Widget _buildPromptSearch(ColorScheme colorScheme) {
    return EmptyState(
      icon: Icons.search_rounded,
      title: 'Cari supplier menggunakan ikon search\ndi pojok kanan atas.',
    );
  }

  Widget _buildList(ColorScheme colorScheme, TextTheme textTheme) {
    return RefreshIndicator(
      onRefresh: _fetchSuppliers,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _suppliers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, idx) {
          if (idx == _suppliers.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildSupplierCard(_suppliers[idx], colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildSupplierCard(
      SupplierModel s, ColorScheme colorScheme, TextTheme textTheme) {
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
        onTap: () => _openDetail(s),
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
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme, TextTheme textTheme) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: _errorMessage!,
      subtitle: 'Terjadi kesalahan saat memuat data',
      action: ElevatedButton.icon(
        onPressed: _fetchSuppliers,
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
