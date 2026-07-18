import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/readiness_model.dart';
import '../services/readiness_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/modern_bottom_nav.dart';
import 'home_page.dart';
import 'hrd_dashboard_page.dart';
import 'stock_dashboard_page.dart';
import 'transaction_dashboard_page.dart';
import 'readiness_page.dart';

class ReadinessAdminListPage extends StatefulWidget {
  const ReadinessAdminListPage({super.key});

  @override
  State<ReadinessAdminListPage> createState() => _ReadinessAdminListPageState();
}

class _ReadinessAdminListPageState extends State<ReadinessAdminListPage> {
  final ReadinessService _service = ReadinessService();
  List<ReadinessModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

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
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await _service.getAdminList(date: dateStr);
      if (!mounted) return;
      setState(() {
        _items = data;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(int? status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.success;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _statusLabel(int? status) {
    switch (status) {
      case 1:
        return 'Belum diperiksa';
      case 2:
        return 'Terverifikasi';
      default:
        return 'Unknown';
    }
  }

  Widget _thumb(String? url, IconData icon) {
    if (url == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusSM,
        ),
        child: Icon(icon, color: AppColors.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusSM,
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 44,
          height: 44,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.onSurfaceVariant),
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
        title: const Text('Kesiapan Diri (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingMD,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                  ),
                ),
                AppSpacing.gapHorizontalMD,
                Text(
                  '${_items.length} entri',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: AppSpacing.paddingLG,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
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
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5)),
                                AppSpacing.gapVerticalMD,
                                Text(
                                  'Belum ada laporan kesiapan untuk tanggal ini.',
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
                                    item.createdByName ?? 'Tanpa nama',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.storeName ?? 'Toko'),
                                      Text(
                                        _formatDate(item.createdAt),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                                      _thumb(
                                          item.rightHandUrl, Icons.front_hand),
                                      AppSpacing.gapHorizontalXS,
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(item.status)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              AppSpacing.borderRadiusSM,
                                        ),
                                        child: Text(
                                          _statusLabel(item.status),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: _statusColor(item.status),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReadinessPage()),
          );
          _load();
        },
        tooltip: 'Kesiapan Diri Baru',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 4,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }
}
