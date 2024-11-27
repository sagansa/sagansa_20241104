import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../services/payment_method_service.dart';
import '../widgets/modern_button.dart';
import 'payment_success_page.dart';
import '../services/transaction_service.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../services/printer_service.dart';

class CheckOutPage extends StatefulWidget {
  final int finalTotal;

  const CheckOutPage({
    super.key,
    required this.finalTotal,
  });

  @override
  State<CheckOutPage> createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> {
  PaymentMethodModel? selectedPayment;
  final TextEditingController _cashController = TextEditingController();
  int? _cashAmount;
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  List<PaymentMethodModel> paymentMethods = [];
  bool isLoading = true;
  CustomerModel? selectedCustomer;
  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _paymentMethodService.getPaymentMethods();
      setState(() {
        paymentMethods = methods;
        isLoading = false;
      });
    } catch (e) {
      // print('Error loading payment methods: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat metode pembayaran: $e')),
        );
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'qr_code':
        return Icons.qr_code;
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  String formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _showCustomerModal() async {
    bool isAddingCustomer = false;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAddingCustomer ? 'Tambah Customer' : 'Pilih Customer',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          if (!isAddingCustomer)
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () =>
                                  setState(() => isAddingCustomer = true),
                            ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(),
                  if (isAddingCustomer) ...[
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Customer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    ModernButton(
                      text: 'Simpan Customer',
                      onPressed: () async {
                        try {
                          final newCustomer =
                              await _customerService.createCustomer(
                            name: nameController.text,
                            noTelp: phoneController.text,
                          );
                          this.setState(() {
                            selectedCustomer = newCustomer;
                          });
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal menambah customer: $e')),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    OutlinedButton(
                      child: Text('Kembali'),
                      onPressed: () => setState(() => isAddingCustomer = false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 45),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: FutureBuilder<List<CustomerModel>>(
                        future: _customerService.getCustomers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          final customers = snapshot.data ?? [];

                          return ListView.builder(
                            itemCount: customers.length,
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(customer.name[0]),
                                ),
                                title: Text(customer.name),
                                subtitle: Text(customer.noTelp ?? ''),
                                onTap: () {
                                  this.setState(() {
                                    selectedCustomer = customer;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Contoh URL QR dari database
    final String qrImageUrl = 'https://example.com/qr-codes/payment123.png';

    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text(selectedCustomer?.name ?? 'Pilih Customer'),
                      subtitle: selectedCustomer != null
                          ? Text(selectedCustomer!.noTelp ?? '')
                          : null,
                      trailing: Icon(Icons.chevron_right),
                      onTap: _showCustomerModal,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    formatPrice(widget.finalTotal),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else
                    ...paymentMethods
                        .map((method) => Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: RadioListTile<PaymentMethodModel>(
                                title: Row(
                                  children: [
                                    Icon(_getIconForType(method.type)),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            method.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                value: method,
                                groupValue: selectedPayment,
                                onChanged: (value) {
                                  setState(() {
                                    selectedPayment = value;
                                    if (value?.type != 'cash') {
                                      _cashAmount = null;
                                    }
                                  });
                                },
                              ),
                            ))
                        .toList(),
                  if (selectedPayment?.type == 'cash') ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masukkan Nominal Uang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _cashController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nominal uang',
                              prefixText: 'Rp ',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                String cleanValue = value.replaceAll('.', '');
                                int? parsed = int.tryParse(cleanValue);
                                if (parsed != null) {
                                  String formatted = parsed
                                      .toString()
                                      .replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (Match m) => '${m[1]}.',
                                      );
                                  if (formatted != value) {
                                    _cashController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(
                                          offset: formatted.length),
                                    );
                                  }
                                  setState(() {
                                    _cashAmount = parsed;
                                  });
                                }
                              } else {
                                setState(() {
                                  _cashAmount = null;
                                });
                              }
                            },
                          ),
                          if (_cashAmount != null) ...[
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Uang Tunai:',
                                    style: TextStyle(fontSize: 16)),
                                Text(formatPrice(_cashAmount!),
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Kembalian:',
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                  _cashAmount! >= widget.finalTotal
                                      ? formatPrice(
                                          _cashAmount! - widget.finalTotal)
                                      : 'Uang kurang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _cashAmount! >= widget.finalTotal
                                        ? Colors.blue
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (selectedPayment?.type == 'qr_code') ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Scan QR Code untuk membayar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                qrImageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 50,
                                      color: Colors.red,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Menunggu pembayaran...',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ModernButton(
                text: 'Bayar Sekarang',
                onPressed: selectedPayment == null ||
                        (selectedPayment?.type == 'cash' &&
                            (_cashAmount == null ||
                                _cashAmount! < widget.finalTotal))
                    ? null
                    : () async {
                        try {
                          // Tampilkan loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final transactionService = TransactionService();

                          // Data yang akan dikirim
                          final paidAmount = selectedPayment?.type == 'cash'
                              ? _cashAmount!
                              : widget.finalTotal;

                          // print('Mengirim data transaksi:');
                          // print('Payment Method: ${selectedPayment?.name}');
                          // print('Paid Amount: $paidAmount');
                          // print('Total Amount: ${widget.finalTotal}');
                          // print(
                          //     'Change Amount: ${selectedPayment?.type == 'cash' ? _cashAmount! - widget.finalTotal : 0}');

                          final result =
                              await transactionService.createTransaction(
                            paidAmount: paidAmount,
                            paymentMethod: selectedPayment!.name,
                          );

                          // Tutup loading dialog
                          Navigator.pop(context);

                          if (result['status'] == 'success') {
                            // Cetak struk
                            try {
                              final printers =
                                  await PrinterService.getPrinters();

                              // Cari printer yang bisa mencetak struk
                              final receiptPrinter = printers.firstWhere(
                                (printer) =>
                                    printer['printReceiptAndBills'] == true,
                                orElse: () => throw Exception(
                                    'Printer struk belum dikonfigurasi'),
                              );

                              // Gunakan receiptPrinter untuk mencetak struk
                              await PrinterService.connectAndPrint(
                                  receiptPrinter);
                            } catch (e) {
                              print('Error printing: $e');
                              // Lanjutkan ke halaman sukses meskipun print gagal
                            }
                            // Cari printer yang bisa mencetak pesanan
                            // final orderPrinter = printers.firstWhere(
                            //   (printer) => printer['printOrders'] == true,
                            //   orElse: () => throw Exception(
                            //       'Printer pesanan belum dikonfigurasi'),
                            // );

                            // Implementasi pencetakan pesanan
                            // await PrinterService.connectAndPrint(orderPrinter);

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentSuccessPage(
                                  // transactionData: result['data'],
                                  paymentMethod: selectedPayment!.name,
                                  totalAmount: widget.finalTotal,
                                  cashAmount: selectedPayment?.type == 'cash'
                                      ? _cashAmount
                                      : null,
                                  changeAmount: selectedPayment?.type == 'cash'
                                      ? _cashAmount! - widget.finalTotal
                                      : null,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          // Tutup loading dialog jika masih terbuka
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal membuat transaksi: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt() async {
    try {
      final printers = await PrinterService.getPrinters();

      // Cari printer yang bisa mencetak struk
      final receiptPrinter = printers.firstWhere(
        (printer) => printer['printReceiptAndBills'] == true,
        orElse: () => throw Exception('Printer struk belum dikonfigurasi'),
      );

      // Gunakan receiptPrinter untuk mencetak struk
      await PrinterService.connectAndPrint(receiptPrinter);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak: $e')),
      );
    }
  }

  Future<void> _printOrder() async {
    try {
      // Mendapatkan daftar printer
      final printers = await PrinterService.getPrinters();

      // Cari printer yang bisa mencetak pesanan
      final orderPrinter = printers.firstWhere(
        (printer) => printer['printOrders'] == true,
        orElse: () => throw Exception('Printer pesanan belum dikonfigurasi'),
      );

      // Implementasi pencetakan pesanan
      await PrinterService.connectAndPrint(orderPrinter);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak: $e')),
      );
    }
  }
}
