import 'package:flutter/material.dart';
import '../models/salary_model.dart';
import '../services/salary_service.dart';
import 'salary_detail_page.dart';
import '../widgets/modern_bottom_nav.dart';
import '../utils/format_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalaryPage extends StatefulWidget {
  const SalaryPage({Key? key}) : super(key: key);

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  late Future<void> _initializationFuture;
  late SalaryService _salaryService;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeService();
  }

  Future<void> _initializeService() async {
    final token = await _getToken();
    _salaryService = SalaryService(token);
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Gaji'),
            ),
            body: FutureBuilder<List<SalaryModel>>(
              future: _salaryService.getAllSalaries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No salary data available.'));
                } else {
                  final salaries = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: salaries.length,
                    itemBuilder: (context, index) {
                      final salary = salaries[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SalaryDetailPage(salary: salary.toJson()),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  salary.formattedMonth,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      FormatUtils.formatCurrency(salary.amount),
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
                                        color: salary.paymentStatus ==
                                                'sudah dibayar'
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        salary.paymentStatus,
                                        style: TextStyle(
                                          color: salary.paymentStatus ==
                                                  'sudah dibayar'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tanggal Bayar: ${salary.paymentDate ?? 'belum dibayar'}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
            bottomNavigationBar: ModernBottomNav(
              currentIndex: 4,
              onTap: (index) {},
            ),
          );
        }
      },
    );
  }
}
