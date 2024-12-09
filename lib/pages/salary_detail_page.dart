import 'package:flutter/material.dart';
import '../utils/format_utils.dart';

class SalaryDetailPage extends StatelessWidget {
  final Map<String, dynamic> salary;

  const SalaryDetailPage({Key? key, required this.salary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Salary ${salary['month']} ${salary['year']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Daily Salary', [
              _buildDetailItem('Total Hour Days', salary['totalHourDays'],
                  isCurrency: false),
              _buildDetailItem('Total Working Days', salary['totalWorkingDays'],
                  isCurrency: false),
              _buildDetailItem('Total Daily Salary', salary['totalDailySalary'],
                  isCurrency: true),
            ]),
            const SizedBox(height: 16),
            _buildSection('Monthly Salary', [
              _buildDetailItem('Gross Salary', salary['grossSalary'],
                  isCurrency: true),
              _buildDetailItem('Cash Advance', salary['cashAdvance'],
                  isCurrency: true),
              _buildDetailItem('Deductions', salary['deductions'],
                  isCurrency: true),
              _buildDetailItem('Net Salary', salary['netSalary'],
                  isCurrency: true, isHighlighted: true),
              _buildDetailItem(
                  'Payment Status',
                  salary['paymentStatus'] == true
                      ? 'Terbayar'
                      : 'Belum Terbayar',
                  isCurrency: false),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, dynamic value,
      {bool isHighlighted = false, bool isCurrency = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            isCurrency
                ? FormatUtils.formatCurrency((value ?? 0) as int)
                : value?.toString() ?? '-',
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
