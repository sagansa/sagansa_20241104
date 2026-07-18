import 'package:flutter/material.dart';
import '../models/hygiene_model.dart';
import '../services/hygiene_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_nav.dart';
import 'home_page.dart';
import 'hrd_dashboard_page.dart';
import 'stock_dashboard_page.dart';
import 'transaction_dashboard_page.dart';
import 'hygiene_detail_page.dart';
import 'hygiene_page.dart';

class HygieneListPage extends StatefulWidget {
  const HygieneListPage({super.key});

  @override
  State<HygieneListPage> createState() => _HygieneListPageState();
}

class _HygieneListPageState extends State<HygieneListPage> {
  final HygieneService _service = HygieneService();
  List<HygieneModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == 4) return;
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HRDDashboardPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StockDashboardPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TransactionDashboardPage(),
          ),
        );
        break;
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getHistory();
      if (!mounted) return;
      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat daftar kebersihan: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.success;
      case 3:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('List Kebersihan Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Segarkan',
          ),
        ],
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
                        Text(_errorMessage!,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.error)),
                        AppSpacing.gapVerticalMD,
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cleaning_services_outlined,
                              size: 56,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                          AppSpacing.gapVerticalMD,
                          Text(
                            'Belum ada laporan kebersihan.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: AppSpacing.paddingMD,
                        itemCount: _items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = _items[idx];
                          final dirtyRooms = item.rooms
                              .where((r) => r.condition == 3 || r.condition == 2)
                              .length;
                          final photos = item.rooms
                              .where((r) => r.imageUrl != null)
                              .map((r) => r.imageUrl!)
                              .toList();
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HygieneDetailPage(
                                        hygiene: item),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: AppSpacing.paddingMD,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                AppSpacing.borderRadiusSM,
                                          ),
                                          child: Icon(
                                            Icons
                                                .cleaning_services_outlined,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        AppSpacing.gapHorizontalSM,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.storeName ?? 'Toko',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                item.createdByName ?? '-',
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (dirtyRooms > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      AppSpacing.borderRadiusXL,
                                                ),
                                                child: Text(
                                                  '$dirtyRooms perlu perhatian',
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: AppColors.error,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            AppSpacing.gapVerticalXS,
                                            Text(
                                              item.statusLabel,
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: _statusColor(item.status),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (photos.isNotEmpty) ...[
                                      AppSpacing.gapVerticalSM,
                                      SizedBox(
                                        height: 72,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: photos.length,
                                          separatorBuilder: (_, __) =>
                                              AppSpacing.gapHorizontalXS,
                                          itemBuilder: (context, pidx) {
                                            return ClipRRect(
                                              borderRadius:
                                                  AppSpacing.borderRadiusSM,
                                              child: Image.network(
                                                photos[pidx],
                                                width: 72,
                                                height: 72,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  width: 72,
                                                  height: 72,
                                                  color: colorScheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.3),
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ] else ...[
                                      AppSpacing.gapVerticalXS,
                                      Text(
                                        _formatDate(item.createdAt),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HygienePage()),
          );
          _load();
        },
        tooltip: 'Inspeksi Kebersihan Baru',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 4,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }
}
