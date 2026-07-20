import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../services/closing_store_service.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';
import '../widgets/add_fab.dart';
import '../widgets/fuel_service_payment_bottom_sheet.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/list_thumbnail.dart';
import '../providers/fuel_service_payment_provider.dart';
import 'fuel_service_form_page.dart';

class FuelServiceListPage extends StatefulWidget {
  const FuelServiceListPage({super.key});

  @override
  State<FuelServiceListPage> createState() => _FuelServiceListPageState();
}

class _FuelServiceListPageState extends State<FuelServiceListPage> {
  final ClosingStoreService _service = ClosingStoreService();
  final ScrollController _scrollController = ScrollController();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _errorMessage;
  List<Map<String, dynamic>> _services = [];
  bool _isAdmin = false;
  bool _paymentMode = false;

  // Filter state (dipakai admin saja untuk scope; status/fuelService untuk semua).
  // scope: 0 = Semua, 1 = Saya (admin only, hidden untuk staff)
  // status: 0 = Semua, 1 = Pending, 2 = Lunas
  // fuelService: 0 = Semua, 1 = Fuel, 2 = Service
  int _scopeFilter = 0;
  int _statusFilter = 0;
  int _fuelServiceFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
    _fetch();
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

  Future<void> _loadAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = json.decode(userString);
      final roles = List<String>.from(userData['roles'] ?? []);
      if (mounted) {
        setState(() {
          _isAdmin = roles.contains('admin') ||
              roles.contains('super_admin') ||
              roles.contains('supervisor');
        });
      }
    }
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
      _services = [];
      _hasMore = true;
    });

    try {
      final result = await _service.getFuelServicesPaged(
        allStores: _isAdmin,
        page: _page,
        scope: _scopeFilter == 1 ? 'me' : 'all',
        status: _statusFilter == 0 ? null : _statusFilter.toString(),
        fuelService: _fuelServiceFilter == 0 ? null : _fuelServiceFilter.toString(),
      );
      if (!mounted) return;
      setState(() {
        _services = result['data'] as List<Map<String, dynamic>>;
        _hasMore = result['has_more'] as bool;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _service.getFuelServicesPaged(
        allStores: _isAdmin,
        page: _page + 1,
        scope: _scopeFilter == 1 ? 'me' : 'all',
        status: _statusFilter == 0 ? null : _statusFilter.toString(),
        fuelService: _fuelServiceFilter == 0 ? null : _fuelServiceFilter.toString(),
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _services.addAll(result['data'] as List<Map<String, dynamic>>);
        _hasMore = result['has_more'] as bool;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  /// Chip row untuk filter scope/status/fuel_service.
  /// Disembunyikan saat _paymentMode aktif (fokus pilih item).
  Widget _buildFilterRow(ThemeData theme, ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Scope filter (admin only — staff tetap lihat milik sendiri).
          if (_isAdmin) ...[
            _filterChip(
              cs: cs,
              activeIndex: _scopeFilter,
              onTap: (i) {
                setState(() => _scopeFilter = i);
                _fetch();
              },
              options: const ['Semua User', 'Saya'],
            ),
            const SizedBox(width: 16),
            // Separator visual.
            Container(width: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(width: 16),
          ],
          // Fuel/Service filter.
          _filterChip(
            cs: cs,
            activeIndex: _fuelServiceFilter,
            onTap: (i) {
              setState(() => _fuelServiceFilter = i);
              _fetch();
            },
            options: const ['Semua', 'Fuel', 'Service'],
          ),
          const SizedBox(width: 16),
          Container(width: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(width: 16),
          // Status filter.
          _filterChip(
            cs: cs,
            activeIndex: _statusFilter,
            onTap: (i) {
              setState(() => _statusFilter = i);
              _fetch();
            },
            options: const ['Semua', 'Pending', 'Lunas'],
          ),
        ],
      ),
    );
  }

  /// Generic chip group untuk filter dengan options list.
  Widget _filterChip({
    required ColorScheme cs,
    required int activeIndex,
    required void Function(int) onTap,
    required List<String> options,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (i) {
        final selected = activeIndex == i;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
          child: GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _openFuelServiceForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FuelServiceFormPage()),
    );
    if (result == true) {
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_paymentMode ? 'Pilih untuk Bayar Transfer' : 'Bensin & Servis'),
        actions: [
          IconButton(
            icon: Icon(_paymentMode ? Icons.close : Icons.payment),
            tooltip: _paymentMode ? 'Batal' : 'Bayar Transfer',
            onPressed: () {
              setState(() => _paymentMode = !_paymentMode);
              if (!_paymentMode) {
                context.read<FuelServicePaymentProvider>().clearSelection();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          )
        ],
        bottom: _paymentMode
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: _buildFilterRow(theme, colorScheme),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                        AppSpacing.gapVerticalMD,
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge,
                        ),
                        AppSpacing.gapVerticalLG,
                        ElevatedButton(
                          onPressed: _fetch,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_gas_station_outlined, size: 64, color: colorScheme.outline),
                          AppSpacing.gapVerticalMD,
                          Text('Belum ada riwayat bensin atau servis.', style: textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _services.length + (_hasMore ? 1 : 0),
                        padding: AppSpacing.paddingMD,
                        itemBuilder: (context, index) {
                          if (index == _services.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final fs = _services[index];
                        final type = fs['fuel_service'] == 1 ? 'Fuel' : 'Service';
                        final isFuel = fs['fuel_service'] == 1;
                        final amount = double.tryParse(fs['amount'].toString()) ?? 0;
                        final date = fs['date'] ?? '';
                        final vehicleNo = fs['vehicle']?['no_register'] ?? 'Kendaraan';
                        final km = fs['km'] ?? 0;
                        final creatorName = fs['created_by']?['name'] ?? 'Staff';
                        final statusStr = fs['status'] == 2 ? 'Lunas / Terhubung' : 'Pending';
                        final isPaid = fs['status'] == 2;
                        final paymentTypeId = fs['payment_type_id'];
                        final canPayTransfer =
                            _paymentMode && !isPaid && paymentTypeId == 1;
                        final imageUrl = ImageService.buildUrl(fs['image']?.toString());

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (canPayTransfer)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Checkbox(
                                      value: context
                                          .read<FuelServicePaymentProvider>()
                                          .isSelected(fs['id'] as int),
                                      onChanged: (v) {
                                        final amount =
                                            double.tryParse(fs['amount'].toString()) ?? 0;
                                        context
                                            .read<FuelServicePaymentProvider>()
                                            .toggleSelection(
                                              fs['id'] as int,
                                              amount: amount.round(),
                                            );
                                      },
                                    ),
                                  ),
                                ListThumbnail(
                                  imageUrl: imageUrl,
                                  placeholderIcon: Icons.local_gas_station_outlined,
                                  onTap: imageUrl != null
                                      ? () => _showImageFullscreen(imageUrl)
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                            decoration: BoxDecoration(
                                              color: (isFuel ? AppColors.success : AppColors.warning)
                                                  .withValues(alpha: 0.1),
                                              borderRadius: AppSpacing.borderRadiusSM,
                                            ),
                                            child: Text(
                                              type,
                                              style: textTheme.labelMedium?.copyWith(
                                                color: isFuel ? AppColors.success : AppColors.warning,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            currencyFormatter.format(amount),
                                            style: textTheme.titleMedium
                                                ?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      AppSpacing.gapVerticalSM,
                                      Text(
                                        '$vehicleNo (KM: $km)',
                                        style: textTheme.titleSmall
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      AppSpacing.gapVerticalXS,
                                      Text(
                                        'Tanggal: $date | Oleh: $creatorName',
                                        style: textTheme.bodySmall
                                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                      AppSpacing.gapVerticalSM,
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            statusStr,
                                            style: textTheme.labelMedium?.copyWith(
                                              color: isPaid ? AppColors.success : colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (imageUrl != null)
                                            IconButton(
                                              icon: const Icon(Icons.share, size: 18),
                                              onPressed: () => _shareImage(
                                                  imageUrl,
                                                  fs['id']),
                                              tooltip: 'Bagikan',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                        ],
                                      ),
                                      if (fs['notes'] != null) ...[
                                        AppSpacing.gapVerticalXS,
                                        (() {
                                          final stripped = _stripHtmlTags(fs['notes'].toString());
                                          if (stripped.isNotEmpty) {
                                            return Text(
                                              stripped,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(fontStyle: FontStyle.italic),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        })(),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
      floatingActionButton: AddFab(
        onPressed: _openFuelServiceForm,
      ),
      bottomNavigationBar: _paymentMode &&
              context.watch<FuelServicePaymentProvider>().selectedCount > 0
          ? _buildPaymentActionBar()
          : ModernBottomNav(
              currentIndex: 3,
              onTap: (index) {
                if (index != 3) {
                  Navigator.pop(context);
                }
              },
            ),
    );
  }

  void _showImageFullscreen(String url) {
    final colorScheme = Theme.of(context).colorScheme;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.87),
            iconTheme: IconThemeData(color: colorScheme.surface),
            title: Text('Bukti Bensin & Servis',
                style: TextStyle(color: colorScheme.surface)),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image,
                    color: colorScheme.surface.withValues(alpha: 0.54),
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage(String url, dynamic id) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('download failed');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fuel_service_$id.jpg');
      await file.writeAsBytes(response.bodyBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Bukti Bensin & Servis');
    } catch (_) {
      if (mounted) await Share.share(url);
    }
  }

  Widget _buildPaymentActionBar() {
    final provider = context.read<FuelServicePaymentProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.selectedCount} item terpilih',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  FormatUtils.formatCurrency(provider.totalAmount),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await FuelServicePaymentBottomSheet.show(context);
              if (success == true) {
                setState(() => _paymentMode = false);
                _fetch();
              }
            },
            icon: const Icon(Icons.payment),
            label: const Text('Bayar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}



String _stripHtmlTags(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '').trim();
}
