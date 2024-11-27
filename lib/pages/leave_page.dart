import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../widgets/modern_bottom_nav.dart';
import 'leave_form_page.dart';
import '../widgets/modern_fab.dart';
import '../models/presence_model.dart';
import 'package:provider/provider.dart';
import '../providers/presence_provider.dart';

class LeavePage extends StatefulWidget {
  final PresenceModel? todayPresence;

  const LeavePage({Key? key, this.todayPresence}) : super(key: key);

  @override
  _LeavePageState createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  List<LeaveModel> _leaves = [];
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data cuti')),
      );
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange; // Pending
      case 2:
        return Colors.green; // Approved
      case 3:
        return Colors.red; // Rejected
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Leave'),
            centerTitle: true,
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadLeaves,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _leaves.length,
                    itemBuilder: (context, index) {
                      final leave = _leaves[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () async {
                            if (leave.status == 1) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LeaveFormPage(leave: leave),
                                ),
                              );
                              if (result == true) {
                                _loadLeaves();
                              }
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        leave.reasonText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(leave.status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        leave.statusText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.date_range,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(
                                      '${DateFormat('dd MMM yyyy').format(leave.fromDate)} - ${DateFormat('dd MMM yyyy').format(leave.untilDate)}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (leave.notes != null &&
                                    leave.notes!.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.notes,
                                          size: 16, color: Colors.grey),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          leave.notes!,
                                          style: TextStyle(
                                            color: Colors.grey[700],
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
          floatingActionButton: CustomFAB(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaveFormPage()),
              );
              if (result == true) {
                _loadLeaves();
              }
            },
            icon: Icons.event_busy,
            tooltip: 'Tambah Cuti',
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: ModernBottomNav(
            currentIndex: 1,
            onTap: (index) {},
          ),
        );
      },
    );
  }
}
