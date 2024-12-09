import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_detail_model.dart';
import '../services/transaction_service.dart';
import '../services/printer_service.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final _transactionService = TransactionService();
  TransactionDetail? _transaction;
  bool _isLoading = true;
  String? _error;
  bool isCheckedOut = false;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetail();
  }

  Future<void> _loadTransactionDetail() async {
    try {
      setState(() => _isLoading = true);
      final detail = await _transactionService.getTransactionDetail(
        widget.transactionId,
      );
      setState(() {
        _transaction = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _printTransaction() async {
    try {
      final printers = await PrinterService.getPrinters();

      if (printers.isEmpty) {
        throw Exception('Belum ada printer yang dikonfigurasi');
      }

      // Tampilkan dialog pilihan printer jika ada lebih dari 1 printer
      if (printers.length > 1) {
        final selectedPrinter = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pilih Printer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: printers
                    .where((p) => p['printReceiptAndBills'] == true)
                    .map((printer) => ListTile(
                          title: Text(printer['name']),
                          subtitle: Text(
                              printer['connectionType'] == 'bluetooth'
                                  ? 'Bluetooth - ${printer['bluetoothName']}'
                                  : 'LAN - ${printer['ipAddress']}'),
                          onTap: () => Navigator.pop(context, printer),
                        ))
                    .toList(),
              ),
            ),
          ),
        );

        if (selectedPrinter == null) return;
        await _printToSelectedPrinter(selectedPrinter);
      } else {
        // Langsung print jika hanya ada 1 printer
        await _printToSelectedPrinter(printers.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak: $e')),
        );
      }
    }
  }

  Future<void> _printToSelectedPrinter(Map<String, dynamic> printer) async {
    try {
      final data = _generatePrintData();

      if (printer['connectionType'] == 'bluetooth') {
        await _printBluetooth(printer, data);
      } else {
        await _printLAN(printer, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mencetak struk')),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _generatePrintData() {
    return {
      'header': {
        'transactionNumber': _transaction!.transactionNumber,
        'date': _transaction!.createdAt,
        'paymentMethod': _transaction!.formattedPaymentMethod,
      },
      'items': _transaction!.items
          .map((item) => {
                'name': item.productName,
                'variant': item.variant?.name,
                'modifiers': item.modifier
                    ?.map((mod) => {
                          'name': mod.name,
                          'detail': mod.detail.name,
                        })
                    .toList(),
                'notes': item.notes,
                'quantity': item.quantity,
                'price': item.price,
                'subtotal': item.subtotal,
              })
          .toList(),
      'summary': {
        'subtotal': _transaction!.subtotal,
        'discount': _transaction!.discount,
        'total': _transaction!.totalAmount,
      },
    };
  }

  Future<void> _printBluetooth(
      Map<String, dynamic> printer, Map<String, dynamic> data) async {
    // TODO: Implementasi print via bluetooth
    throw UnimplementedError('Print via bluetooth belum diimplementasi');
  }

  Future<void> _printLAN(
      Map<String, dynamic> printer, Map<String, dynamic> data) async {
    // Implementasi print via LAN
    // Gunakan package seperti esc_pos_utils dan esc_pos_printer
  }

  Future<void> _refundTransaction() async {
    if (isCheckedOut) {
      return; // Tidak melakukan apapun jika sudah checkout
    }

    try {
      // Tampilkan dialog konfirmasi
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Refund'),
          content: const Text(
              'Apakah Anda yakin ingin melakukan refund untuk transaksi ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Refund'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Proses refund
      await _transactionService.refundTransaction(widget.transactionId);

      // Reload data
      await _loadTransactionDetail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil direfund')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan refund: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckedOut) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          if (_transaction != null &&
              _transaction!.paymentStatus != 'refunded') ...[
            IconButton(
              icon: const Icon(Icons.money_off),
              onPressed: _refundTransaction,
              tooltip: 'Refund Transaksi',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _transaction != null ? _printTransaction : null,
            tooltip: 'Cetak Struk',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadTransactionDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _transaction != null
                        ? Column(
                            children: [
                              _buildHeader(),
                              const Divider(height: 1),
                              _buildItems(),
                              const Divider(height: 1),
                              _buildSummary(),
                            ],
                          )
                        : const SizedBox(),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No. Transaksi: ${_transaction!.transactionNumber}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanggal: ${DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(_transaction!.createdAt))}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Metode Pembayaran: ${_transaction!.formattedPaymentMethod}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Item',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_transaction!.itemsCount} Items',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._transaction!.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              if (item.variant != null)
                                Text(
                                  item.variant!.name,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              if (item.modifier != null)
                                ...item.modifier!.map((mod) => Text(
                                      "${mod.name}: ${mod.detail.name}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    )),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(
                                  'Catatan: ${item.notes}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(item.subtotal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity}x ${_formatPrice(item.price)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(_formatPrice(_transaction!.subtotal)),
            ],
          ),
          // if (_transaction!.discount > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diskon'),
              Text(
                '- ${_formatPrice(_transaction!.discount)}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
          // ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatPrice(_transaction!.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }
}
