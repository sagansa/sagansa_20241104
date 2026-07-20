import 'package:flutter/material.dart';

import '../models/readiness_model.dart';
import '../services/readiness_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_nav.dart';
import 'home_page.dart';
import 'hrd_dashboard_page.dart';
import 'readiness_page.dart';
import 'stock_dashboard_page.dart';
import 'transaction_dashboard_page.dart';

class ReadinessListPage extends StatefulWidget {
  const ReadinessListPage({super.key});

  @override
  State<ReadinessListPage> createState() => _ReadinessListPageState();
}

class _ReadinessListPageState extends State<ReadinessListPage> {
  final ReadinessService _service = ReadinessService();
  List<ReadinessModel> _items = [];
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
          MaterialPageRoute(builder: (context) => const TransactionDashboardPage()),
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
        _errorMessage = 'Gagal memuat daftar kesiapan: $e';
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

  Widget _thumb(String? url, IconData icon) {
    if (url == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusSM,
        ),
        child: Icon(icon, color: AppColors.info),
      );
    }
    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusSM,
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 48,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.info),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('List Kesiapan Diri'),
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
                          Icon(Icons.checkroom_outlined,
                              size: 56,
                              color: AppColors.info
                                  .withValues(alpha: 0.5)),
                          AppSpacing.gapVerticalMD,
                          Text(
                            'Belum ada laporan kesiapan diri.',
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
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: _thumb(item.selfieUrl, Icons.face),
                            title: Text(
                              item.storeName ?? 'Toko',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.createdByName ?? '-'),
                                Text(
                                  _formatDate(item.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _thumb(item.leftHandUrl, Icons.back_hand),
                                AppSpacing.gapHorizontalXS,
                                _thumb(item.rightHandUrl, Icons.front_hand),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReadinessPage()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 4,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }
}
