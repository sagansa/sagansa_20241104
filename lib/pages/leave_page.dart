import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/modern_fab.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'leave_form_page.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  LeavePageState createState() => LeavePageState();
}

class LeavePageState extends State<LeavePage> {
  List<Leave> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    try {
      final leaves = await LeaveService().getLeaves();
      setState(() {
        _leaves = leaves;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data cuti')),
      );
    }
  }

  Color _getStatusColor(int status) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaves,
              child: ListView.builder(
                padding: AppSpacing.paddingMD,
                itemCount: _leaves.length,
                itemBuilder: (context, index) {
                  final leave = _leaves[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: InkWell(
                      onTap: () async {
                        if (leave.status == 1) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaveFormPage(leave: leave),
                            ),
                          );
                          if (result == true) {
                            _loadLeaves();
                          }
                        }
                      },
                      child: Padding(
                        padding: AppSpacing.paddingMD,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    leave.reasonText,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(leave.status),
                                    borderRadius: AppSpacing.borderRadiusLG,
                                  ),
                                  child: Text(
                                    leave.statusText,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.sectionGap),
                            Row(
                              children: [
                                Icon(Icons.date_range,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                AppSpacing.gapHorizontalSM,
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(leave.fromDate)} - ${DateFormat('dd MMM yyyy').format(leave.untilDate)}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (leave.notes != null &&
                                leave.notes!.isNotEmpty) ...[
                              AppSpacing.gapVerticalSM,
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                  AppSpacing.gapHorizontalSM,
                                  Expanded(
                                    child: Text(
                                      leave.notes!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
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
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            Navigator.pop(context);
          }
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveFormPage()),
          );
          if (result == true) {
            _loadLeaves();
          }
        },
        icon: Icons.event_busy,
        tooltip: 'Tambah Cuti',
      ),
    );
  }
}
