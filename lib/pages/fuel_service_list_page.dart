import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/closing_store_service.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_fab.dart';
import '../widgets/modern_bottom_nav.dart';
import 'fuel_service_form_page.dart';

class FuelServiceListPage extends StatefulWidget {
  const FuelServiceListPage({super.key});

  @override
  State<FuelServiceListPage> createState() => _FuelServiceListPageState();
}

class _FuelServiceListPageState extends State<FuelServiceListPage> {
  final ClosingStoreService _service = ClosingStoreService();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _fuelServices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getFuelServices();
      setState(() {
        _fuelServices = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openFuelServiceForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FuelServiceFormPage()),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bensin & Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
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
                        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                        AppSpacing.gapVerticalMD,
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge,
                        ),
                        AppSpacing.gapVerticalLG,
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _fuelServices.isEmpty
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
                  : ListView.builder(
                      itemCount: _fuelServices.length,
                      padding: AppSpacing.paddingMD,
                      itemBuilder: (context, index) {
                        final fs = _fuelServices[index];
                        final type = fs['fuel_service'] == 1 ? 'Fuel' : 'Service';
                        final isFuel = fs['fuel_service'] == 1;
                        final amount = double.tryParse(fs['amount'].toString()) ?? 0;
                        final date = fs['date'] ?? '';
                        final vehicleNo = fs['vehicle']?['no_register'] ?? 'Kendaraan';
                        final km = fs['km'] ?? 0;
                        final creatorName = fs['created_by']?['name'] ?? 'Staff';
                        final statusStr = fs['status'] == 2 ? 'Lunas / Terhubung' : 'Pending';
                        final isPaid = fs['status'] == 2;

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: (isFuel ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
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
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                AppSpacing.gapVerticalSM,
                                Text(
                                  '$vehicleNo (KM: $km)',
                                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                AppSpacing.gapVerticalXS,
                                Text(
                                  'Tanggal: $date | Oleh: $creatorName',
                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                                (() {
                                  final imageUrl = ImageService.buildUrl(fs['image']?.toString());
                                  if (imageUrl != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: Stack(
                                                alignment: Alignment.topRight,
                                                children: [
                                                  Image.network(imageUrl),
                                                  IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.white),
                                                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                                    onPressed: () => Navigator.pop(context),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: AppSpacing.borderRadiusSM,
                                          child: Image.network(
                                            imageUrl,
                                            width: 100,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 100,
                                              height: 60,
                                              color: colorScheme.surfaceContainerHighest,
                                              child: const Icon(Icons.broken_image, size: 20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                })(),
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
                                    if (fs['notes'] != null) ...[
                                      (() {
                                        final stripped = _stripHtmlTags(fs['notes'].toString());
                                        if (stripped.isNotEmpty) {
                                          return Text(
                                            stripped,
                                            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      })(),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: AddFab(
        onPressed: _openFuelServiceForm,
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}



String _stripHtmlTags(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '').trim();
}
