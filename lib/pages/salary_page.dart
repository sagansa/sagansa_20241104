import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/salary_service.dart';
import 'salary_detail_page.dart';

class SalaryPage extends StatefulWidget {
  const SalaryPage({super.key});

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final SalaryService _salaryService = SalaryService();
  List<Map<String, dynamic>> salaryHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSalaryHistory();
  }

  Future<void> _loadSalaryHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await _salaryService.getSalaryHistory();
      if (!mounted) return;
      setState(() {
        salaryHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat riwayat gaji: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Dibayarkan';
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      default:
        return 'Unknown';
    }
  }

  Widget _buildSalaryCard(Map<String, dynamic> salary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final DateTime periodDate = DateTime.parse(salary['period']);
    final DateTime? paymentDate = salary['paymentDate'] != null 
        ? DateTime.parse(salary['paymentDate']) 
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalaryDetailPage(salaryId: salary['id']),
            ),
          );
        },
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(periodDate),
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: _getStatusColor(salary['status'], colorScheme).withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusMD,
                    ),
                    child: Text(
                      _getStatusText(salary['status']),
                      style: textTheme.labelMedium?.copyWith(
                        color: _getStatusColor(salary['status'], colorScheme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sectionGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormatter.format(salary['amount']),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (paymentDate != null)
                    Text(
                      'Dibayar: ${DateFormat('dd/MM/yyyy').format(paymentDate)}',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Gaji')),
      body: RefreshIndicator(
        onRefresh: _loadSalaryHistory,
        child: Column(
          children: [
            Container(
              padding: AppSpacing.paddingMD,
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  AppSpacing.gapHorizontalSM,
                  Expanded(
                    child: Text(
                      'Gaji bulanan dihitung berdasarkan periode cut-off yang dikonfigurasi HRD.',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
              AppSpacing.gapVerticalMD,
              ElevatedButton(
                onPressed: _loadSalaryHistory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (salaryHistory.isEmpty) {
      return Center(
        child: Text('Belum ada riwayat slip gaji bulanan.'),
      );
    }

    return ListView.builder(
      itemCount: salaryHistory.length,
      itemBuilder: (context, index) {
        return _buildSalaryCard(salaryHistory[index]);
      },
    );
  }
}
