import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/salary_service.dart';
import 'salary_pay_page.dart';

class SalaryDetailPage extends StatefulWidget {
  final int salaryId;
  final String? userName;

  const SalaryDetailPage({
    super.key,
    required this.salaryId,
    this.userName,
  });

  @override
  State<SalaryDetailPage> createState() => _SalaryDetailPageState();
}

class _SalaryDetailPageState extends State<SalaryDetailPage> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final SalaryService _salaryService = SalaryService();
  Map<String, dynamic>? salaryDetail;
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadSalaryDetail();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        if (mounted) {
          setState(() {
            _isAdmin =
                List<String>.from(userData['roles'] ?? []).contains('admin');
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSalaryDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _salaryService.getSalaryDetail(widget.salaryId);
      setState(() {
        salaryDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat rincian gaji: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveSalary() async {
    try {
      await _salaryService.approveSalary(widget.salaryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slip di-approve.')),
        );
      }
      _loadSalaryDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalSM,
            Text(
              value,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(BuildContext context) {
    if (salaryDetail == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    final int baseSalary = salaryDetail!['base_salary'] ?? 0;
    final int dailySalaryTotal = salaryDetail!['daily_salary_total'] ?? 0;
    final Map<String, dynamic> deductions = salaryDetail!['deductions'] ?? {};

    final int latePenalties = deductions['late_penalties'] ?? 0;
    final int manualPenalties = deductions['manual_penalties'] ?? 0;
    final int loanInstallments = deductions['loan_installments'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Komponen Gaji',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildRowItem('Gaji Utama Tenur (A)', currencyFormatter.format(baseSalary)),
            _buildRowItem('Total Gaji Harian (B)', currencyFormatter.format(dailySalaryTotal), isAddition: true),
            if (latePenalties > 0)
              _buildRowItem('Denda Keterlambatan', '- ${currencyFormatter.format(latePenalties)}', isDeduction: true),
            if (manualPenalties > 0)
              _buildRowItem('Denda Manual', '- ${currencyFormatter.format(manualPenalties)}', isDeduction: true),
            if (loanInstallments > 0)
              _buildRowItem('Cicilan Kasbon', '- ${currencyFormatter.format(loanInstallments)}', isDeduction: true),
            const Divider(height: 24),
            _buildRowItem('Total Gaji Akhir (A - Potongan + B)', currencyFormatter.format(salaryDetail!['amount']), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, String value, {bool isAddition = false, bool isDeduction = false, bool isBold = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Color valColor = colorScheme.onSurface;
    if (isAddition) valColor = AppColors.success;
    if (isDeduction) valColor = colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHoursSummary(BuildContext context) {
    if (salaryDetail == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final List<dynamic> dailyWork = salaryDetail!['daily_work'] ?? [];
    final double totalWorkHours = dailyWork.fold<double>(
        0.0, (sum, day) => sum + (day['workHours'] ?? 0.0) + (day['overtime'] ?? 0.0));
    final double regularHours = dailyWork.fold<double>(
        0.0, (sum, day) => sum + (day['workHours'] ?? 0.0));
    final double totalOvertime = dailyWork.fold<double>(
        0.0, (sum, day) => sum + (day['overtime'] ?? 0.0));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Jam Kerja',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.gapVerticalMD,
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        regularHours.toStringAsFixed(1),
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        'Jam Normal',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        totalOvertime.toStringAsFixed(1),
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        'Jam Lembur',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        totalWorkHours.toStringAsFixed(1),
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.info),
                      ),
                      AppSpacing.gapVerticalXS,
                      Text(
                        'Total Jam',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyWorkList() {
    if (salaryDetail == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final List<dynamic> dailyWork = salaryDetail!['daily_work'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingMD,
            child: Text(
              'Detail Harian',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          if (dailyWork.isEmpty)
            Padding(
              padding: AppSpacing.paddingMD,
              child: const Center(child: Text('Tidak ada rincian kerja harian.')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dailyWork.length,
              itemBuilder: (context, index) {
                final day = dailyWork[index];
                final double totalHours = (day['workHours'] ?? 0.0) + (day['overtime'] ?? 0.0);
                final DateTime parsedDate = DateTime.parse(day['date']);

                final bool isNoCheckout = day['status'] == 'no_checkout';

                return ListTile(
                  title: Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsedDate),
                    style: textTheme.titleSmall,
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '${day['workHours']} jam kerja',
                        style: textTheme.bodySmall,
                      ),
                      if (isNoCheckout) ...[
                        AppSpacing.gapHorizontalSM,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusXS,
                          ),
                          child: Text(
                            'Tanpa Checkout',
                            style: textTheme.labelSmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      AppSpacing.gapHorizontalSM,
                      _buildPaymentStatusBadge(day['payment_status'] ?? 'belum_dibayar'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(day['dailyWage']),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isNoCheckout ? colorScheme.onSurfaceVariant : AppColors.success,
                        ),
                      ),
                      Text(
                        '${totalHours.toStringAsFixed(1)} jam',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Gaji')),
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                AppSpacing.gapVerticalMD,
                ElevatedButton(
                  onPressed: _loadSalaryDetail,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (salaryDetail == null) {
      return const Scaffold(
        body: Center(child: Text('Data tidak ditemukan.')),
      );
    }

    final DateTime periodDate = DateTime.parse(salaryDetail!['period']);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName ?? salaryDetail!['user_name'] ?? '',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Slip Gaji ${DateFormat('MMMM yyyy', 'id_ID').format(periodDate)}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: AppSpacing.paddingMD,
              color: _getStatusBackgroundColor(salaryDetail!['status'], colorScheme),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(salaryDetail!['status']),
                    color: _getStatusColor(salaryDetail!['status'], colorScheme),
                  ),
                  AppSpacing.gapHorizontalSM,
                  Expanded(
                    child: Text(
                      _getStatusMessage(salaryDetail!['status']),
                      style: textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(salaryDetail!['status'], colorScheme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSummaryCard(
              context,
              'Total Gaji Bersih (THP)',
              currencyFormatter.format(salaryDetail!['amount']),
              valueColor: AppColors.success,
            ),
            _buildBreakdownCard(context),
            _buildWorkHoursSummary(context),
            _buildDailyWorkList(),
            if (_isAdmin) ...[
              AppSpacing.gapVerticalMD,
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    if (salaryDetail!['status'] == 'draft')
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _approveSalary,
                          icon: const Icon(Icons.check),
                          label: const Text('Approve Slip'),
                        ),
                      ),
                    if (salaryDetail!['status'] == 'processing')
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SalaryPayPage(salaryId: widget.salaryId),
                              ),
                            ).then((ok) {
                              if (ok == true) _loadSalaryDetail();
                            });
                          },
                          icon: const Icon(Icons.payments),
                          label: const Text('Bayar Gaji'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            AppSpacing.gapVerticalLG,
          ],
        ),
      ),
    );
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

  Color _getStatusBackgroundColor(String status, ColorScheme colorScheme) {
    return _getStatusColor(status, colorScheme).withValues(alpha: 0.1);
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.sync;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusMessage(String status) {
    final DateTime? paymentDate = salaryDetail!['paymentDate'] != null 
        ? DateTime.parse(salaryDetail!['paymentDate']) 
        : null;

    switch (status) {
      case 'paid':
        return 'Gaji telah ditransfer pada ${paymentDate != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(paymentDate) : '-'}';
      case 'pending':
        return 'Gaji bulanan Anda masih berstatus draft/menunggu persetujuan.';
      case 'processing':
        return 'Gaji sedang diproses untuk pembayaran.';
      default:
        return 'Status gaji tidak diketahui.';
    }
  }

  Widget _buildPaymentStatusBadge(String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Color color;
    String text;

    switch (status) {
      case 'sudah_dibayar':
        color = AppColors.success;
        text = 'Lunas';
        break;
      case 'siap_dibayar':
        color = AppColors.info;
        text = 'Siap Dibayar';
        break;
      case 'perbaiki':
        color = colorScheme.error;
        text = 'Perbaiki';
        break;
      case 'belum_dibayar':
      default:
        color = AppColors.warning;
        text = 'Belum Dibayar';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusXS,
      ),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
