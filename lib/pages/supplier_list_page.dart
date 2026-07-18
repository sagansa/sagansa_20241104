import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/supplier_model.dart';
import '../services/supplier_service.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';
import '../widgets/add_fab.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import 'supplier_detail_page.dart';
import 'supplier_form_page.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  final SupplierService _service = SupplierService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasSearched = false;
  bool _canManage = false;
  String? _errorMessage;
  int? _selectedStatus;
  int _page = 1;

  static const int _minSearchLength = 3;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _onSearchChanged() {
    if (!mounted) return;
    final query = _searchController.text.trim();
    if (query.length >= _minSearchLength) {
      _fetchSuppliers();
    } else {
      setState(() {
        _suppliers = [];
        _hasSearched = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _fetchSuppliers() async {
    final query = _searchController.text.trim();
    if (query.length < _minSearchLength && _selectedStatus == null) {
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
      final query = _searchController.text.trim();
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
      appBar: AppBar(title: const Text('Supplier')),
      floatingActionButton: _canManage
          ? AddFab(onPressed: () => _openForm())
          : null,
      body: Column(
        children: [
          _buildSearchAndFilter(colorScheme, textTheme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildError(colorScheme, textTheme)
                    : !_hasSearched
                        ? _buildPromptSearch(colorScheme)
                        : _suppliers.isEmpty
                            ? _buildEmpty(colorScheme)
                            : _buildList(colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(
      ColorScheme colorScheme, TextTheme textTheme) {
    final filterOptions = [
      {'label': 'Semua', 'value': null},
      {'label': 'Belum Diperiksa', 'value': 1},
      {'label': 'Valid', 'value': 2},
      {'label': 'Blacklist', 'value': 3},
    ];

    final query = _searchController.text.trim();
    final charsLeft = _minSearchLength - query.length;

    return Container(
      color: colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md + AppSpacing.xs,
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.md + AppSpacing.xs,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _fetchSuppliers(),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Cari nama, bank, no rekening...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          if (query.isNotEmpty && query.length < _minSearchLength)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
              child: Text(
                'Ketik $charsLeft huruf lagi untuk mencari...',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          AppSpacing.gapVerticalSM,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((opt) {
                final isSelected = _selectedStatus == opt['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(opt['label'] as String),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(
                          () => _selectedStatus = opt['value'] as int?);
                      _fetchSuppliers();
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    checkmarkColor: colorScheme.primary,
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          AppSpacing.gapVerticalSM,
        ],
      ),
    );
  }

  Widget _buildPromptSearch(ColorScheme colorScheme) {
    return EmptyState(
      icon: Icons.search_rounded,
      title: 'Ketik minimal $_minSearchLength huruf\nuntuk mencari supplier.',
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
                              color: colorScheme.onSurfaceVariant),
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
                              color: colorScheme.onSurfaceVariant),
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
                  color: colorScheme.onSurfaceVariant),
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
