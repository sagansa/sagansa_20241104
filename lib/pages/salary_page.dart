import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presence_today_model.dart';
import '../services/global_service.dart';
import '../utils/constants.dart';
import '../widgets/modern_bottom_nav.dart';
import '../utils/format_utils.dart';
import 'salary_detail_page.dart';
import '../providers/presence_provider.dart';

class SalaryPage extends StatefulWidget {
  const SalaryPage({Key? key}) : super(key: key);

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  late GlobalService _globalService;
  bool _hasPresenceToday = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    _globalService = GlobalService(token: token);
    await _checkPresenceToday();
  }

  Future<void> _checkPresenceToday() async {
    try {
      final PresenceTodayModel presenceToday =
          await _globalService.getPresenceToday();
      if (mounted) {
        setState(() {
          _hasPresenceToday = presenceToday.hasPresence;
        });
      }
    } catch (e) {
      print('Error checking presence: $e');
      if (mounted) {
        setState(() {
          _hasPresenceToday = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gaji'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) {
              final salary = <String, dynamic>{
                'bulan': 'Maret 2024',
                'gajiBersih': 1000000,
                'status': 'Dibayar',
                'tanggalBayar': '25 Maret 2024',
                // Tambahkan data lain yang diperlukan
              };
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salary['bulan'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            FormatUtils.formatCurrency(salary['gajiBersih']),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              salary['status'],
                              style: const TextStyle(
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tanggal Bayar: ${salary['tanggalBayar']}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalaryDetailPage(
                                salary: salary,
                              ),
                            ),
                          );
                        },
                        child: const Text('Detail Gaji'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: ModernBottomNav(
            currentIndex: 4,
            onTap: (index) {
              if (index != 4) {
                if (index == 3) {
                  Navigator.pushNamed(context, '/calendar');
                } else {
                  Navigator.pop(context);
                }
              }
            },
            hasPresenceToday: _hasPresenceToday,
          ),
        );
      },
    );
  }
}
