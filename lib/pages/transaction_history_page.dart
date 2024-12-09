import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_history_model.dart';
import '../services/transaction_service.dart';
import 'transaction_detail_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionService _transactionService = TransactionService();
  DateTime? startDate;
  DateTime? endDate;
  String selectedPaymentMethod = 'Semua';
  List<TransactionHistoryModel> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    try {
      final result = await _transactionService.getTransactionHistory();
      setState(() {
        transactions = result;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      print('Error loading transactions: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildStatusFilter(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? Center(child: Text('Tidak ada transaksi'))
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(transactions[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          _buildFilterChip('Hari Ini', () {
            setState(() {
              startDate = DateTime.now();
              endDate = DateTime.now();
            });
          }),
          SizedBox(width: 8),
          _buildFilterChip('7 Hari', () {
            setState(() {
              startDate = DateTime.now().subtract(Duration(days: 7));
              endDate = DateTime.now();
            });
          }),
          SizedBox(width: 8),
          _buildFilterChip('30 Hari', () {
            setState(() {
              startDate = DateTime.now().subtract(Duration(days: 30));
              endDate = DateTime.now();
            });
          }),
          SizedBox(width: 8),
          _buildFilterChip('Custom', _showDateRangePicker),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedPaymentMethod,
        decoration: InputDecoration(
          labelText: 'Metode Pembayaran',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        items: ['Semua', 'Cash', 'QRIS', 'Debit', 'Credit Card', 'E-Wallet']
            .map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedPaymentMethod = value!;
          });
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionHistoryModel transaction) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailPage(
                transactionId: transaction.id.toString(),
              ),
            ),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              transaction.transactionNumber,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: transaction.paymentStatus.toLowerCase() == 'paid'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.paymentStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: transaction.paymentStatus.toLowerCase() == 'paid'
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy HH:mm:ss')
                  .format(DateTime.parse(transaction.createdAt)),
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              formatPrice(transaction.totalAmount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add your filter options here
          ],
        ),
        actions: [
          TextButton(
            child: Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Terapkan'),
            onPressed: () {
              Navigator.pop(context);
              _loadTransactions();
            },
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: startDate ?? DateTime.now().subtract(Duration(days: 7)),
        end: endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadTransactions();
    }
  }

  String formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }
}
