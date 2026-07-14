import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/closing_store_service.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/add_fab.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/list_thumbnail.dart';
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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getFuelServices(allStores: _isAdmin);
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListThumbnail(
                                  imageUrl: ImageService.buildUrl(fs['image']?.toString()),
                                  placeholderIcon: Icons.local_gas_station_outlined,
                                  onTap: ImageService.buildUrl(fs['image']?.toString()) != null
                                      ? () => _showImageFullscreen(
                                          ImageService.buildUrl(fs['image']?.toString())!)
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
                                          if (ImageService.buildUrl(fs['image']?.toString()) != null)
                                            IconButton(
                                              icon: const Icon(Icons.share, size: 18),
                                              onPressed: () => _shareImage(
                                                  ImageService.buildUrl(fs['image']?.toString())!,
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
}



String _stripHtmlTags(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '').trim();
}
