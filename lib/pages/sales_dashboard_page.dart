import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_dashboard_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  SalesPeriode _periode = SalesPeriode.today;
  bool _accessChecked = false;
  bool _canAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    bool ok = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString) as Map<String, dynamic>;
        final roles = List<String>.from(userData['roles'] ?? []);
        ok = roles.contains('admin') || roles.contains('super_admin');
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _canAccess = ok;
      _accessChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (!_accessChecked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Penjualan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_canAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Penjualan')),
        body: const Center(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Text('Anda tidak punya akses ke fitur ini.'),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Penjualan'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Ringkasan'),
              Tab(text: 'Produk'),
              Tab(text: 'Channel'),
            ],
            labelColor: cs.onSurface,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: Column(
          children: [
            _buildPeriodeRow(),
            const Expanded(
              child: TabBarView(
                children: [
                  _PlaceholderTab(text: 'Ringkasan — diisi di Task 12'),
                  _PlaceholderTab(text: 'Produk — diisi di Task 13'),
                  _PlaceholderTab(text: 'Channel — diisi di Task 14'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeRow() {
    return Container(
      padding: AppSpacing.paddingSM,
      color: AppColors.surfaceVariant,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: SalesPeriode.values.map((p) {
          final selected = p == _periode;
          return ChoiceChip(
            label: Text(p.label),
            selected: selected,
            onSelected: (_) {
              setState(() => _periode = p);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.onSurface,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String text;
  const _PlaceholderTab({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
