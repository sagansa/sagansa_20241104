import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/image_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/presence_service.dart';
import '../services/thermal_printer_service.dart';
import '../providers/printer_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DeliveryPage extends StatefulWidget {
  final String orderFor;
  const DeliveryPage({super.key, this.orderFor = '3'});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  ColorScheme get colorScheme => Theme.of(context).colorScheme;
  TextTheme get textTheme => Theme.of(context).textTheme;

  final TextEditingController _receiptController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedStatus = 3; // 3 = Sudah dikirim, 6 = Dikembalikan

  bool _isLoadingSearch = false;
  bool _isLoadingSubmit = false;
  bool _isLoadingReadyToShip = false;
  bool _isPrintingPaymentProof = false;
  bool _isPrintingSticker = false;
  bool _isLoadingList = false;

  Map<String, dynamic>? _selectedOrder;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _orders = [];
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitialOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _receiptController.dispose();
    _receiverController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadInitialOrders() async {
    if (_isLoadingList) return;
    setState(() {
      _isLoadingList = true;
      _currentPage = 1;
      _orders.clear();
      _hasMore = true;
    });

    try {
      final result = await PresenceService.getSalesOrders(page: 1, perPage: 10, orderFor: widget.orderFor);
      if (!mounted) return;
      if (result['success'] == true) {
        final List<dynamic> fetchedOrders = result['data'] ?? [];
        final Map<String, dynamic> meta = result['meta'] ?? {};
        final int lastPage = meta['last_page'] ?? 1;

        setState(() {
          _orders = fetchedOrders;
          _hasMore = _currentPage < lastPage;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat list order: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingList = false;
        });
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingList || !_hasMore) return;
    setState(() {
      _isLoadingList = true;
    });

    final nextPage = _currentPage + 1;

    try {
      final result =
          await PresenceService.getSalesOrders(page: nextPage, perPage: 10, orderFor: widget.orderFor);
      if (!mounted) return;
      if (result['success'] == true) {
        final List<dynamic> fetchedOrders = result['data'] ?? [];
        final Map<String, dynamic> meta = result['meta'] ?? {};
        final int lastPage = meta['last_page'] ?? 1;

        setState(() {
          _currentPage = nextPage;
          _orders.addAll(fetchedOrders);
          _hasMore = _currentPage < lastPage;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data lanjutan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingList = false;
        });
      }
    }
  }

  Future<void> _searchOrder() async {
    final receiptNo = _receiptController.text.trim();
    if (receiptNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan masukkan nomor resi terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _imageFile = null;
      _receiverController.clear();
    });

    try {
      final result = await PresenceService.searchSalesOrder(receiptNo, orderFor: widget.orderFor);
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _selectedOrder = result['data'];
          _imageFile = null;
          _receiverController.clear();
          _notesController.clear();
          if (_selectedOrder?['received_by'] != null) {
            _receiverController.text = _selectedOrder!['received_by'];
          }
          final currentStatus = _selectedOrder?['delivery_status'] ?? 3;
          _selectedStatus = (currentStatus == 6) ? 6 : 3;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order tidak ditemukan.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSearch = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1024,
      );

      if (!mounted) return;
      if (photo != null) {
        final compressed = await ImageUtils.compressImage(photo.path);
        if (mounted) {
          setState(() {
            _imageFile = compressed;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submitDelivery() async {
    if (_selectedOrder == null) return;

    final receiptNo = _selectedOrder!['receipt_no'];
    
    // Validasi foto (hanya wajib untuk status 3 / Sudah Dikirim)
    if (_selectedStatus == 3 && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap ambil foto bukti pengiriman terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validasi nama penerima (wajib jika online order & status 3 / Sudah Dikirim)
    if (widget.orderFor == '3' && _selectedStatus == 3 && _receiverController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap isi nama penerima terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedStatus == 6 && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap isi alasan barang dikembalikan pada catatan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingSubmit = true;
    });

    try {
      final result = await PresenceService.updateDeliveryStatus(
        receiptNo: receiptNo,
        imageFile: _imageFile,
        receivedBy: _selectedStatus == 6 ? null : _receiverController.text.trim(),
        deliveryStatus: _selectedStatus,
        notes: _selectedStatus == 6 ? _notesController.text.trim() : null,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['message'] ?? 'Status pengiriman berhasil diperbarui.'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedOrder = null;
          _imageFile = null;
          _receiptController.clear();
          _receiverController.clear();
          _notesController.clear();
          _selectedStatus = 3; // Reset to default
        });
        _loadInitialOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memperbarui pengiriman.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubmit = false;
        });
      }
    }
  }

  Future<void> _markReadyToShip() async {
    if (_selectedOrder == null) return;

    final orderId = int.tryParse(_selectedOrder!['id'].toString());
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ID order tidak tersedia.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingReadyToShip = true;
    });

    try {
      final result = await PresenceService.markReadyToShip(
        orderId: orderId,
        orderFor: widget.orderFor,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['message'] ?? 'Order berhasil ditandai siap dikirim.'),
            backgroundColor: AppColors.success,
          ),
        );

        setState(() {
          _selectedOrder = {
            ..._selectedOrder!,
            'delivery_status': result['data']?['delivery_status'] ?? 4,
          };
        });
        _loadInitialOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Gagal mengubah status menjadi siap dikirim.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReadyToShip = false;
        });
      }
    }
  }

  bool _canPrintPaymentProof(Map<String, dynamic> order) {
    return order['delivery_status'] == 1 && _hasPaymentProof(order);
  }

  bool _hasPaymentProof(Map<String, dynamic> order) {
    return order['image_payment_url'] != null &&
        order['image_payment_url'].toString().trim().isNotEmpty;
  }

  bool _isPaymentProofPrinted(Map<String, dynamic> order) {
    return order['payment_proof_printed_at'] != null &&
        order['payment_proof_printed_at'].toString().trim().isNotEmpty;
  }

  bool _isUnprintedPaymentProof(Map<String, dynamic> order) {
    return _canPrintPaymentProof(order) && !_isPaymentProofPrinted(order);
  }

  String _getPaymentProofPrintStatusText(Map<String, dynamic> order) {
    if (!_hasPaymentProof(order)) {
      return 'Bukti bayar belum ada';
    }

    return _isPaymentProofPrinted(order)
        ? 'Bukti bayar sudah diprint'
        : 'Bukti bayar belum diprint';
  }

  String _getPaymentStatusText(dynamic status) {
    switch (status?.toString()) {
      case '1':
        return 'Sudah Dibayar';
      case '2':
        return 'Valid';
      case '3':
        return 'Tidak Valid';
      case '4':
        return 'Menunggu Pembayaran';
      default:
        return '-';
    }
  }

  Color _getPaymentStatusColor(dynamic status) {
    switch (status?.toString()) {
      case '1':
        return AppColors.warning;
      case '2':
        return AppColors.success;
      case '3':
        return AppColors.error;
      case '4':
        return AppColors.info;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Color _getPaymentProofPrintStatusColor(Map<String, dynamic> order) {
    if (!_hasPaymentProof(order)) {
      return AppColors.onSurfaceVariant;
    }

    return _isPaymentProofPrinted(order) ? AppColors.success : colorScheme.primary;
  }

  int _getPaymentProofPrintCount(Map<String, dynamic> order) {
    final count = order['payment_proof_print_count'];
    if (count is int) {
      return count;
    }

    return int.tryParse(count?.toString() ?? '') ?? 0;
  }

  Future<Uint8List> _downloadImageBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat gambar bukti pembayaran.');
    }

    return response.bodyBytes;
  }

  Future<void> _printPaymentProofs(List<Map<String, dynamic>> orders) async {
    final printableOrders = orders.where(_canPrintPaymentProof).toList();

    if (printableOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Tidak ada bukti pembayaran status belum dikirim untuk diprint.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isPrintingPaymentProof = true;
    });

    try {
      final document = pw.Document();
      final printedOrderIds = <int>[];
      final failedReceipts = <String>[];

      for (final order in printableOrders) {
        try {
          final imageBytes =
              await _downloadImageBytes(order['image_payment_url'].toString());
          final image = pw.MemoryImage(imageBytes);

          document.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(24),
              build: (context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                widget.orderFor == '3'
                                    ? 'Bukti Pembayaran Online'
                                    : 'Bukti Pembayaran Direct',
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text('Resi: ${order['receipt_no'] ?? '-'}'),
                              pw.Text('Toko: ${order['store_name'] ?? '-'}'),
                              if (widget.orderFor == '3')
                                pw.Text(
                                    'Provider: ${order['provider_name'] ?? '-'}')
                              else ...[
                                pw.Text(
                                    'Metode Bayar: ${order['payment_method'] ?? '-'}'),
                                if (order['bank_name'] != null)
                                  pw.Text(
                                      'Rekening: ${order['bank_name']} - ${order['bank_account_number']}'),
                              ],
                              pw.Text(
                                  'Jasa Kirim: ${order['delivery_service_name'] ?? '-'}'),
                              pw.Text(
                                  'Tanggal Kirim: ${order['delivery_date'] ?? '-'}'),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.orange50,
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            'Belum Dikirim',
                            style: pw.TextStyle(
                              color: PdfColors.orange800,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Expanded(
                      child: pw.Container(
                        width: double.infinity,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ],
                );
              },
            ),
          );

          final id = int.tryParse(order['id'].toString());
          if (id != null) {
            printedOrderIds.add(id);
          }
        } catch (_) {
          failedReceipts.add(order['receipt_no']?.toString() ?? '-');
        }
      }

      if (printedOrderIds.isEmpty) {
        throw Exception('Semua gambar bukti pembayaran gagal dimuat.');
      }

      final printCompleted = await Printing.layoutPdf(
        name: widget.orderFor == '3'
            ? 'bukti-pembayaran-online.pdf'
            : 'bukti-pembayaran-direct.pdf',
        onLayout: (_) async => document.save(),
      );

      if (printCompleted && printedOrderIds.isNotEmpty) {
        await PresenceService.markPaymentProofsPrinted(
          orderIds: printedOrderIds,
        );

        if (!mounted) return;
        final printedAt = DateTime.now().toIso8601String();
        setState(() {
          _orders = _orders.map((order) {
            final orderId = int.tryParse(order['id'].toString());
            if (orderId != null && printedOrderIds.contains(orderId)) {
              final updatedOrder = Map<String, dynamic>.from(order);
              updatedOrder['payment_proof_printed_at'] = printedAt;
              updatedOrder['payment_proof_print_status'] = 'printed';
              updatedOrder['payment_proof_print_status_label'] =
                  'Sudah pernah diprint';
              updatedOrder['payment_proof_print_count'] =
                  _getPaymentProofPrintCount(updatedOrder) + 1;
              return updatedOrder;
            }
            return order;
          }).toList();

          if (_selectedOrder != null) {
            final selectedId = int.tryParse(_selectedOrder!['id'].toString());
            if (selectedId != null && printedOrderIds.contains(selectedId)) {
              _selectedOrder = {
                ..._selectedOrder!,
                'payment_proof_printed_at': printedAt,
                'payment_proof_print_status': 'printed',
                'payment_proof_print_status_label': 'Sudah pernah diprint',
                'payment_proof_print_count':
                    _getPaymentProofPrintCount(_selectedOrder!) + 1,
              };
            }
          }
        });

        final failedMessage = failedReceipts.isEmpty
            ? ''
            : ' ${failedReceipts.length} gambar gagal dimuat.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status print ${printedOrderIds.length} bukti pembayaran diperbarui.$failedMessage'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrintingPaymentProof = false;
        });
      }
    }
  }

  Future<void> _printSticker(Map<String, dynamic> order) async {
    final provider = context.read<PrinterProvider>();
    final service = ThermalPrinterService.instance;

    setState(() => _isPrintingSticker = true);

    try {
      final data = StickerData.fromOrderMap(order);
      bool ok;
      String message;

      if (provider.isEnabled) {
        ok = await service.printStickerViaWifi(
          data: data,
          ip: provider.ip,
          port: provider.port,
          copies: provider.copies,
        );
        message = ok
            ? 'Stiker dicetak via WiFi (${provider.formattedEndpoint}, '
                '${provider.copies}x).'
            : 'Gagal mencetak stiker via WiFi.';
      } else {
        ok = await service.printStickerViaSpooler(
          data: data,
          widthMm: provider.widthMm,
          heightMm: provider.heightMm,
          fontSize: provider.fontSize,
          docName: 'resi-stiker-${order['receipt_no'] ?? ''}',
        );
        message = ok
            ? 'Stiker dikirim ke spooler (${provider.formattedSize}).'
            : 'Gagal mencetak stiker.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPrintingSticker = false);
      }
    }
  }

  Future<void> _printAllPendingPaymentProofs() async {
    final List<Map<String, dynamic>> allOrders = [];
    var page = 1;
    var lastPage = 1;

    try {
      do {
        final result = await PresenceService.getSalesOrders(
          page: page,
          perPage: 100,
          deliveryStatus: 1,
          hasPaymentProof: true,
          paymentProofPrinted: false,
          orderFor: widget.orderFor,
        );
        if (result['success'] != true) {
          throw Exception(
              result['message'] ?? 'Gagal memuat daftar pengiriman.');
        }

        final fetchedOrders = (result['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        allOrders.addAll(fetchedOrders);

        final meta = result['meta'] as Map<String, dynamic>? ?? {};
        lastPage = meta['last_page'] ?? page;
        page += 1;
      } while (page <= lastPage);

      await _printPaymentProofs(
        allOrders.where(_isUnprintedPaymentProof).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getDeliveryStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Belum Dikirim';
      case 2:
        return 'Valid (Terkunci)';
      case 3:
        return 'Sudah Dikirim';
      case 4:
        return 'Siap Dikirim';
      case 5:
        return 'Perbaiki';
      case 6:
        return 'Dikembalikan';
      default:
        return 'Tidak Diketahui';
    }
  }

  Color _getDeliveryStatusColor(int? status) {
    switch (status) {
      case 2:
        return AppColors.success;
      case 3:
        return colorScheme.primary;
      case 1:
      case 4:
        return AppColors.warning;
      case 5:
      case 6:
        return AppColors.error;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  Widget _buildGoldTextField({
    required String labelText,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: colorScheme.onSurface),
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedOrder == null
              ? (widget.orderFor == '3' ? 'PENGIRIMAN ONLINE' : 'PENGIRIMAN DIRECT')
              : 'DETAIL PENGIRIMAN',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        leading: _selectedOrder != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedOrder = null;
                    _imageFile = null;
                    _receiverController.clear();
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitialOrders,
          child: _selectedOrder != null
              ? _buildOrderDetailView()
              : _buildOrderListView(),
        ),
      ),
    );
  }

  Widget _buildOrderListView() {
    return ListView(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (widget.orderFor == '3') ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildGoldTextField(
                    labelText: 'Cari Nomor Resi / Scan QR & Barcode',
                    controller: _receiptController,
                    prefixIcon: Icons.search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      if (!_isLoadingSearch) {
                        _searchOrder();
                      }
                    },
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_receiptController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _receiptController.clear();
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          tooltip: 'Scan QR/Barcode',
                          onPressed: _scanBarcode,
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward, color: colorScheme.primary, size: 20),
                          tooltip: 'Cari',
                          onPressed: () {
                            if (!_isLoadingSearch) {
                              _searchOrder();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoadingSearch) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        AppSpacing.gapVerticalMD,

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Pengiriman',
              style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            if (_isLoadingList && _currentPage == 1)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: colorScheme.primary, strokeWidth: 2),
              ),
          ],
        ),
        AppSpacing.gapVerticalXS,
        if (widget.orderFor != '1') ...[
          ElevatedButton.icon(
            onPressed:
                _isPrintingPaymentProof ? null : _printAllPendingPaymentProofs,
            icon: _isPrintingPaymentProof
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.print, color: colorScheme.onPrimary),
            label: Text(
              _isPrintingPaymentProof
                  ? 'Menyiapkan Print...'
                  : 'Print Bukti Pembayaran Belum Dikirim & Belum Diprint',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          AppSpacing.gapVerticalSM,
        ],

        if (_orders.isEmpty && !_isLoadingList)
          _buildEmptyState()
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _orders.length) {
                return Padding(
                  padding: AppSpacing.paddingVerticalMD,
                  child: Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  ),
                );
              }

              final order = _orders[index];
              final int? status = order['delivery_status'];

              return Card(
                color: colorScheme.surface,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedOrder = order;
                      _imageFile = null;
                      _receiverController.clear();
                      _notesController.clear();
                      if (order['received_by'] != null) {
                        _receiverController.text = order['received_by'];
                      }
                      final currentStatus = order['delivery_status'] ?? 3;
                      _selectedStatus = (currentStatus == 6) ? 6 : 3;
                    });
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
                                widget.orderFor == '1'
                                    ? 'Order #${order['id']}'
                                    : (order['receipt_no'] ?? 'Tanpa Resi'),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                             Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: _getDeliveryStatusColor(status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: AppSpacing.borderRadiusSM,
                                  ),
                                  child: Text(
                                    _getDeliveryStatusText(status),
                                    style: TextStyle(
                                      color: _getDeliveryStatusColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (widget.orderFor == '1') ...[
                                  AppSpacing.gapHorizontalXS,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: _getPaymentStatusColor(
                                          order['payment_status'])
                                      .withValues(alpha: 0.12),
                                      borderRadius: AppSpacing.borderRadiusSM,
                                    ),
                                    child: Text(
                                      _getPaymentStatusText(
                                          order['payment_status']),
                                      style: TextStyle(
                                        color: _getPaymentStatusColor(
                                            order['payment_status']),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        Divider(
                            height: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.1)),
                        Row(
                          children: [
                            Icon(Icons.storefront,
                                size: 16, color: colorScheme.primary),
                            AppSpacing.gapHorizontalSM,
                            Expanded(
                              child: Text(
                                order['store_name'] ?? '-',
                                style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapVerticalXS,
                        Row(
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 16, color: colorScheme.primary),
                            AppSpacing.gapHorizontalSM,
                            Expanded(
                              child: Text(
                                widget.orderFor == '3'
                                    ? '${order['provider_name'] ?? '-'} • ${order['delivery_service_name'] ?? '-'}'
                                    : '${order['payment_method'] ?? '-'} • ${order['delivery_service_name'] ?? '-'}',
                                style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        if (order['delivery_date'] != null) ...[
                          AppSpacing.gapVerticalXS,
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: colorScheme.primary),
                              AppSpacing.gapHorizontalSM,
                              Text(
                                order['delivery_date'],
                                style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                        if (widget.orderFor == '1') ...[
                          if (order['ordered_by_name'] != null) ...[
                            AppSpacing.gapVerticalXS,
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 16, color: colorScheme.primary),
                                AppSpacing.gapHorizontalSM,
                                Expanded(
                                  child: Text(
                                    'Order By: ${order['ordered_by_name']}',
                                    style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (order['address_detail'] != null) ...[
                            AppSpacing.gapVerticalXS,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 16, color: colorScheme.primary),
                                AppSpacing.gapHorizontalSM,
                                Expanded(
                                  child: Text(
                                    'Penerima: ${order['address_recipient_name'] ?? ''} (${order['address_recipient_telp_no'] ?? ''})\n'
                                    'Alamat: ${order['address_detail'] ?? ''}, ${order['address_subdistrict'] ?? ''}, ${order['address_district'] ?? ''}, ${order['address_city'] ?? ''}, ${order['address_province'] ?? ''}',
                                    style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            AppSpacing.gapVerticalXS,
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 16, color: colorScheme.primary),
                                AppSpacing.gapHorizontalSM,
                                const Expanded(
                                  child: Text(
                                    'Alamat: -',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (order['items'] != null &&
                              (order['items'] as List).isNotEmpty) ...[
                            AppSpacing.gapVerticalXS,
                            Container(
                              width: double.infinity,
                              padding: AppSpacing.paddingXS,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(alpha: 0.03),
                                borderRadius: AppSpacing.borderRadiusSM,
                                border: Border.all(
                                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                                    width: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daftar Barang:',
                                    style: textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  AppSpacing.gapVerticalXS,
                                  ...(order['items'] as List).map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.xs),
                                      child: Text(
                                        '• ${item['product_name']} (${item['quantity']} ${item['product_unit'] ?? ''})',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ],
                        if (widget.orderFor != '1') ...[
                          AppSpacing.gapVerticalXS,
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: _getPaymentProofPrintStatusColor(
                                      Map<String, dynamic>.from(order))
                                  .withValues(alpha: 0.12),
                              borderRadius: AppSpacing.borderRadiusSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPaymentProofPrinted(
                                          Map<String, dynamic>.from(order))
                                      ? Icons.check_circle_outline
                                      : Icons.print_outlined,
                                  size: 14,
                                  color: _getPaymentProofPrintStatusColor(
                                      Map<String, dynamic>.from(order)),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    _getPaymentProofPrintStatusText(
                                        Map<String, dynamic>.from(order)),
                                    style: TextStyle(
                                      color: _getPaymentProofPrintStatusColor(
                                          Map<String, dynamic>.from(order)),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_canPrintPaymentProof(
                              Map<String, dynamic>.from(order))) ...[
                            AppSpacing.gapVerticalSM,
                            OutlinedButton.icon(
                              onPressed: _isPrintingPaymentProof
                                  ? null
                                  : () => _printPaymentProofs([
                                        Map<String, dynamic>.from(order),
                                      ]),
                              icon: const Icon(Icons.print, size: 18),
                              label: Text(
                                _isPaymentProofPrinted(
                                        Map<String, dynamic>.from(order))
                                    ? 'Print Ulang Bukti Pembayaran'
                                    : 'Print Bukti Pembayaran',
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildOnlineOrderDetailView(
    Map<String, dynamic> order,
    bool isLocked,
    bool canMarkReadyToShip,
    bool canSubmitDelivery,
    int deliveryStatus,
  ) {
    final String receiptNo = order['receipt_no'] ?? '-';
    final String providerName = order['provider_name'] ?? '-';
    final String storeName = order['store_name'] ?? '-';
    final String deliveryServiceName = order['delivery_service_name'] ?? '-';
    final String deliveryDate = order['delivery_date'] ?? '-';
    final String printStatus = _getPaymentProofPrintStatusText(order);

    // Address and Recipient Info
    final String recipientName = order['address_recipient_name'] ?? order['received_by'] ?? '-';
    final String recipientPhone = order['address_recipient_telp_no'] ?? '-';
    final String addressName = order['address_name'] ?? '';

    final String fullAddress = [
      if (order['address_detail'] != null && order['address_detail'].toString().trim().isNotEmpty)
        order['address_detail'].toString().trim(),
      if (order['address_subdistrict'] != null && order['address_subdistrict'].toString().trim().isNotEmpty)
        'Kec. ${order['address_subdistrict']}',
      if (order['address_district'] != null && order['address_district'].toString().trim().isNotEmpty)
        order['address_district'].toString().trim(),
      if (order['address_city'] != null && order['address_city'].toString().trim().isNotEmpty)
        order['address_city'].toString().trim(),
      if (order['address_province'] != null && order['address_province'].toString().trim().isNotEmpty)
        order['address_province'].toString().trim(),
    ].join(', ');

    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleek Inline Back Button & Header
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.primary),
                onPressed: () {
                  setState(() {
                    _selectedOrder = null;
                    _imageFile = null;
                    _receiverController.clear();
                  });
                },
              ),
              Text(
                'Detail Pengiriman Online',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMD,

          // Card 1: Status & Info Transaksi Utama
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              providerName,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDeliveryStatusColor(order['delivery_status'])
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getDeliveryStatusText(order['delivery_status']),
                          style: textTheme.bodySmall?.copyWith(
                            color: _getDeliveryStatusColor(order['delivery_status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Resi: $receiptNo',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toko',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              storeName,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order['ordered_by_name'] != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dipesan Oleh',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order['ordered_by_name'],
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapVerticalMD,

          // Card 2: Informasi Penerima & Alamat
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_pin_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Penerima & Alamat Kirim',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Penerima',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recipientName,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recipientPhone != '-' && recipientPhone.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.copy, size: 18, color: colorScheme.primary),
                          tooltip: 'Salin nomor telepon',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: recipientPhone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nomor telepon disalin ke clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nomor Telepon',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recipientPhone,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Alamat Pengiriman',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (addressName.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      addressName,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.secondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fullAddress.isEmpty ? '-' : fullAddress,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (fullAddress.isNotEmpty && fullAddress != '-')
                        IconButton(
                          icon: Icon(Icons.copy, size: 18, color: colorScheme.primary),
                          tooltip: 'Salin alamat lengkap',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: fullAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alamat lengkap disalin ke clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapVerticalMD,

          // Card 3: Informasi Ekspedisi
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_shipping,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Informasi Pengiriman',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jasa Kirim',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              deliveryServiceName,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Kirim',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              deliveryDate,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Cetak Label',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        printStatus,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Penerima',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order['received_by'] ?? '-',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          AppSpacing.gapVerticalMD,

          // Card 4: Daftar Produk
          Card(
            color: colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Daftar Produk',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  if (order['items'] != null && (order['items'] as List).isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (order['items'] as List).length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = order['items'][index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item['quantity']} ${item['product_unit'] ?? 'pcs'}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['product_name'] ?? '-',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Tidak ada rincian produk.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AppSpacing.gapVerticalMD,

          // Bukti Pembayaran (jika ada)
          if (order['image_payment_url'] != null) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: colorScheme.primary, size: 18),
                        AppSpacing.gapHorizontalSM,
                        Text(
                          'Foto Bukti Pembayaran',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalSM,
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusMD,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  InteractiveViewer(
                                    child: Image.network(
                                      order['image_payment_url'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        color: colorScheme.onSurface, size: 30),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.network(
                              order['image_payment_url'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: AppColors.error, size: 36),
                                      AppSpacing.gapVerticalSM,
                                      Text(
                                        'Gagal memuat gambar',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: double.infinity,
                              color: colorScheme.onSurface.withValues(alpha: 0.54),
                              padding:
                                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Text(
                                'Klik untuk memperbesar gambar',
                                style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMD,
          ],

          // Print Bukti Pembayaran
          if (_canPrintPaymentProof(order)) ...[
            ElevatedButton.icon(
              onPressed: _isPrintingPaymentProof
                  ? null
                  : () => _printPaymentProofs([
                        Map<String, dynamic>.from(order),
                      ]),
              icon: _isPrintingPaymentProof
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.print, color: colorScheme.onPrimary),
              label: Text(
                _isPrintingPaymentProof
                    ? 'Menyiapkan Print...'
                    : _isPaymentProofPrinted(order)
                        ? 'Print Ulang Bukti Pembayaran'
                        : 'Print Bukti Pembayaran',
                style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold),
              ),
            ),
            AppSpacing.gapVerticalMD,
          ],

          // Cetak Resi Stiker (khusus online)
          _buildStickerPrintButton(order),
          AppSpacing.gapVerticalMD,

          // Foto Bukti Pengiriman (jika ada)
          if (order['image_delivery_url'] != null) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo, color: colorScheme.primary, size: 18),
                        AppSpacing.gapHorizontalSM,
                        Text(
                          'Foto Bukti Pengiriman',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalSM,
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusMD,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  InteractiveViewer(
                                    child: Image.network(
                                      order['image_delivery_url'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        color: colorScheme.onSurface, size: 30),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.network(
                              order['image_delivery_url'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: AppColors.error, size: 36),
                                      AppSpacing.gapVerticalSM,
                                      Text(
                                        'Gagal memuat gambar',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: double.infinity,
                              color: colorScheme.onSurface.withValues(alpha: 0.54),
                              padding:
                                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Text(
                                'Klik untuk memperbesar gambar',
                                style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMD,
          ],

          // Form Input Pengiriman / Konfirmasi Siap Kirim
          if (canMarkReadyToShip) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: AppColors.warning, size: 20),
                        AppSpacing.gapHorizontalSM,
                        Expanded(
                          child: Text(
                            'Order Belum Siap Dikirim',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalXS,
                    Text(
                      'Tandai order ini sebagai siap dikirim sebelum mengunggah bukti pengiriman.',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    AppSpacing.gapVerticalMD,
                    ElevatedButton.icon(
                      onPressed:
                          _isLoadingReadyToShip ? null : _markReadyToShip,
                      icon: _isLoadingReadyToShip
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.local_shipping,
                              color: colorScheme.onPrimary),
                      label: Text(
                        _isLoadingReadyToShip
                            ? 'Memproses...'
                            : 'Tandai Siap Dikirim',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold),
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (canSubmitDelivery) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kirim Bukti Pengiriman',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    AppSpacing.gapVerticalMD,
                    _buildGoldTextField(
                      labelText: 'Nama Penerima (Wajib)',
                      controller: _receiverController,
                      prefixIcon: Icons.person_outline,
                    ),
                    AppSpacing.gapVerticalMD,
                    if (_imageFile != null) ...[
                      ClipRRect(
                        borderRadius: AppSpacing.borderRadiusMD,
                        child: Image.file(
                          _imageFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                    ],
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: Icon(Icons.camera_alt, color: colorScheme.onSurface),
                      label: Text(
                        _imageFile == null
                            ? 'Ambil Foto Bukti Pengiriman'
                            : 'Ambil Ulang Foto',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                    AppSpacing.gapVerticalMD,
                    ElevatedButton(
                      onPressed: _imageFile == null
                          ? null
                          : () {
                              if (!_isLoadingSubmit) {
                                if (_receiverController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Harap isi nama penerima terlebih dahulu.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Konfirmasi Pengiriman'),
                                      content: const Text(
                                          'Apakah Anda yakin ingin mengirim bukti pengiriman ini? '
                                          'Status pengiriman akan diubah menjadi "Sudah Dikirim" dan tidak dapat diubah lagi.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _selectedStatus = 3;
                                            });
                                            _submitDelivery();
                                          },
                                          child: const Text('Ya, Kirim'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                      child: _isLoadingSubmit
                          ? CircularProgressIndicator(color: colorScheme.onPrimary)
                          : Text(
                              'Kirim Bukti Pengiriman',
                              style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMD,
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.assignment_return),
              label: const Text('Refund / Kembalikan Order', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                _showRefundDialog();
              },
            ),
          ] else ...[
            Builder(builder: (context) {
              final isStatusTwo = deliveryStatus == 2;
              final isStatusSix = deliveryStatus == 6;
              Color cardColor = const Color(0xFF1F2E35);
              if (isStatusTwo) {
                cardColor = const Color(0xFF142B1A);
              } else if (isStatusSix) {
                cardColor = const Color(0xFF2C1919);
              }

              IconData icon = Icons.local_shipping;
              Color iconColor = colorScheme.primary;
              String statusText = 'Orderan ini sudah dikirim.';

              if (isStatusTwo) {
                icon = Icons.check_circle;
                iconColor = AppColors.success;
                statusText = 'Orderan ini sudah divalidasi oleh admin dan tidak dapat diubah lagi.';
              } else if (isStatusSix) {
                icon = Icons.assignment_return;
                iconColor = AppColors.error;
                statusText = 'Orderan ini dikembalikan.';
              }

              return Card(
                color: cardColor,
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                      ),
                      AppSpacing.gapHorizontalSM,
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showRefundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final ColorScheme dialogColorScheme = Theme.of(context).colorScheme;
        final TextTheme dialogTextTheme = Theme.of(context).textTheme;

        return AlertDialog(
          backgroundColor: dialogColorScheme.surface,
          title: Row(
            children: [
              Icon(Icons.assignment_return, color: AppColors.error),
              const SizedBox(width: 10),
              Text(
                'Konfirmasi Refund / Kembalikan',
                style: dialogTextTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dialogColorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin mengembalikan order ini? Status pengiriman akan diubah menjadi "Dikembalikan" dan tidak dapat diubah lagi.',
            style: dialogTextTheme.bodyMedium?.copyWith(
              color: dialogColorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: dialogColorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedStatus = 6;
                  _imageFile = null;
                  _notesController.text = 'Refund oleh storage staff';
                });
                _submitDelivery();
              },
              child: const Text('Ya, Kembalikan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderDetailView() {
    final order = _selectedOrder!;
    final int deliveryStatus = order['delivery_status'] ?? 1;
    final bool isLocked = deliveryStatus == 2 || deliveryStatus == 6 || deliveryStatus == 3;
    final bool canMarkReadyToShip = deliveryStatus == 1;
    final bool canSubmitDelivery = !isLocked && !canMarkReadyToShip;

    if (widget.orderFor == '3') {
      return _buildOnlineOrderDetailView(order, isLocked, canMarkReadyToShip, canSubmitDelivery, deliveryStatus);
    }

    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedOrder = null;
                _imageFile = null;
                _receiverController.clear();
              });
            },
            child: Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios,
                        size: 16, color: colorScheme.primary),
                    AppSpacing.gapHorizontalSM,
                    Text(
                      'Kembali ke Daftar Pengiriman',
                      style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.gapVerticalMD,

          Card(
            color: colorScheme.surface,
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
                          widget.orderFor == '1'
                              ? 'Order #${order['id']}'
                              : 'Resi: ${order['receipt_no']}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: _getDeliveryStatusColor(
                                  order['delivery_status'])
                              .withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: Text(
                          _getDeliveryStatusText(order['delivery_status']),
                          style: textTheme.bodySmall?.copyWith(
                            color: _getDeliveryStatusColor(
                                order['delivery_status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                      height: 24,
                      color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  _buildDetailRow('Toko', order['store_name'] ?? '-'),
                  if (widget.orderFor == '3')
                    _buildDetailRow(
                        'Online Provider', order['provider_name'] ?? '-')
                  else ...[
                    _buildDetailRow(
                        'Metode Bayar', order['payment_method'] ?? '-'),
                    _buildDetailRow('Status Bayar',
                        _getPaymentStatusText(order['payment_status'])),
                    if (order['bank_name'] != null)
                      _buildDetailRow(
                        'Rekening Tujuan',
                        '${order['bank_name']} - ${order['bank_account_number']} (${order['bank_account_name']})',
                      ),
                  ],
                  _buildDetailRow(
                      'Jasa Kirim', order['delivery_service_name'] ?? '-'),
                  _buildDetailRow(
                      'Tanggal Kirim', order['delivery_date'] ?? '-'),
                  if (isLocked)
                    _buildDetailRow('Penerima', order['received_by'] ?? '-'),
                  AppSpacing.gapVerticalMD,
                  Text(
                    'Detail Produk:',
                    style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                  AppSpacing.gapVerticalSM,
                  if (order['items'] != null &&
                      (order['items'] as List).isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (order['items'] as List).length,
                      itemBuilder: (context, index) {
                        final item = order['items'][index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 6, color: colorScheme.primary),
                              AppSpacing.gapHorizontalSM,
                              Expanded(
                                child: Text(
                                  '${item['product_name']} x ${item['quantity']} ${item['product_unit'] ?? ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    Text('Tidak ada rincian produk.',
                        style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          AppSpacing.gapVerticalMD,

          if (order['image_payment_url'] != null) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: colorScheme.primary, size: 18),
                        AppSpacing.gapHorizontalSM,
                        Text(
                          'Foto Bukti Pembayaran',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalSM,
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusMD,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  InteractiveViewer(
                                    child: Image.network(
                                      order['image_payment_url'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        color: colorScheme.onSurface, size: 30),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.network(
                              order['image_payment_url'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: AppColors.error, size: 36),
                                      AppSpacing.gapVerticalSM,
                                      Text(
                                        'Gagal memuat gambar',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: double.infinity,
                              color: colorScheme.onSurface.withValues(alpha: 0.54),
                              padding:
                                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Text(
                                'Klik untuk memperbesar gambar',
                                style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMD,
          ],

          if (widget.orderFor == '3') _buildStickerPrintButton(order),

          if (order['image_delivery_url'] != null) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo, color: colorScheme.primary, size: 18),
                        AppSpacing.gapHorizontalSM,
                        Text(
                          'Foto Bukti Pengiriman',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalSM,
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusMD,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  InteractiveViewer(
                                    child: Image.network(
                                      order['image_delivery_url'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        color: colorScheme.onSurface, size: 30),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.network(
                              order['image_delivery_url'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: AppColors.error, size: 36),
                                      AppSpacing.gapVerticalSM,
                                      Text(
                                        'Gagal memuat gambar',
                                        style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: double.infinity,
                              color: colorScheme.onSurface.withValues(alpha: 0.54),
                              padding:
                                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Text(
                                'Klik untuk memperbesar gambar',
                                style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMD,
          ],

          if (canMarkReadyToShip) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: AppColors.warning, size: 20),
                        AppSpacing.gapHorizontalSM,
                        Expanded(
                          child: Text(
                            'Order Belum Siap Dikirim',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalXS,
                    Text(
                      'Tandai order ini sebagai siap dikirim sebelum mengunggah bukti pengiriman.',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    AppSpacing.gapVerticalMD,
                    ElevatedButton.icon(
                      onPressed:
                          _isLoadingReadyToShip ? null : _markReadyToShip,
                      icon: _isLoadingReadyToShip
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.local_shipping,
                              color: colorScheme.onPrimary),
                      label: Text(
                        _isLoadingReadyToShip
                            ? 'Memproses...'
                            : 'Tandai Siap Dikirim',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold),
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (canSubmitDelivery) ...[
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStatus == 6
                          ? 'Laporkan Barang Kembali'
                          : 'Kirim Bukti Pengiriman',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    AppSpacing.gapVerticalMD,
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Sudah Dikirim')),
                            selected: _selectedStatus == 3,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatus = 3;
                                });
                              }
                            },
                          ),
                        ),
                        AppSpacing.gapHorizontalSM,
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Dikembalikan')),
                            selected: _selectedStatus == 6,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatus = 6;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalMD,
                    if (_selectedStatus == 3)
                      _buildGoldTextField(
                        labelText: 'Nama Penerima (Opsional)',
                        controller: _receiverController,
                        prefixIcon: Icons.person_outline,
                      )
                    else
                      _buildGoldTextField(
                        labelText: 'Alasan Pengembalian (Wajib)',
                        controller: _notesController,
                        prefixIcon: Icons.notes_outlined,
                      ),
                    AppSpacing.gapVerticalMD,
                    if (_imageFile != null) ...[
                      ClipRRect(
                        borderRadius: AppSpacing.borderRadiusMD,
                        child: Image.file(
                          _imageFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      AppSpacing.gapVerticalSM,
                    ],
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: Icon(Icons.camera_alt, color: colorScheme.onSurface),
                      label: Text(
                        _imageFile == null
                            ? (_selectedStatus == 6
                                ? 'Ambil Foto Bukti Retur'
                                : 'Ambil Foto Bukti Pengiriman')
                            : 'Ambil Ulang Foto',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                    AppSpacing.gapVerticalMD,
                    ElevatedButton(
                      onPressed: _imageFile == null
                          ? null
                          : () {
                              if (!_isLoadingSubmit) {
                                _submitDelivery();
                              }
                            },
                      child: _isLoadingSubmit
                          ? CircularProgressIndicator(color: colorScheme.onPrimary)
                          : Text(
                              _selectedStatus == 6
                                  ? 'Laporkan Barang Kembali'
                                  : 'Kirim Bukti Pengiriman',
                              style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Builder(builder: (context) {
              final isStatusTwo = deliveryStatus == 2;
              final isStatusSix = deliveryStatus == 6;
              Color cardColor = const Color(0xFF1F2E35);
              if (isStatusTwo) {
                cardColor = const Color(0xFF142B1A);
              } else if (isStatusSix) {
                cardColor = const Color(0xFF2C1919);
              }

              IconData icon = Icons.local_shipping;
              Color iconColor = colorScheme.primary;
              String statusText = 'Orderan ini sudah dikirim.';

              if (isStatusTwo) {
                icon = Icons.check_circle;
                iconColor = AppColors.success;
                statusText = 'Orderan ini sudah divalidasi oleh admin dan tidak dapat diubah lagi.';
              } else if (isStatusSix) {
                icon = Icons.assignment_return;
                iconColor = AppColors.error;
                statusText = 'Orderan ini dikembalikan.';
              }

              return Card(
                color: cardColor,
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                      ),
                      AppSpacing.gapHorizontalSM,
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStickerPrintButton(Map<String, dynamic> order) {
    return Consumer<PrinterProvider>(
      builder: (context, provider, _) {
        final bool thermalReady = provider.isEnabled;

        return Card(
          color: colorScheme.surface,
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      thermalReady ? Icons.wifi : Icons.receipt_long,
                      color: thermalReady ? AppColors.success : colorScheme.primary,
                      size: 20,
                    ),
                    AppSpacing.gapHorizontalSM,
                    Expanded(
                      child: Text(
                        'Cetak Resi Stiker',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (thermalReady)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: const Text(
                          'WiFi',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: const Text(
                          'Spooler',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapVerticalXS,
                Text(
                  thermalReady
                      ? 'Printer: ${provider.formattedEndpoint} • '
                          '${provider.formattedSize} • ${provider.copies}x'
                      : 'Ukuran: ${provider.formattedSize} • '
                          'Aktifkan thermal di Pengaturan untuk WiFi.',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                AppSpacing.gapVerticalSM,
                OutlinedButton.icon(
                  onPressed: _isPrintingSticker
                      ? null
                      : () => _printSticker(order),
                  icon: _isPrintingSticker
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          thermalReady ? Icons.print : Icons.receipt_outlined,
                          size: 18,
                        ),
                  label: Text(
                    _isPrintingSticker
                        ? 'Mencetak...'
                        : 'Cetak Stiker Resi'
                            '${provider.copies > 1 ? ' (${provider.copies}x)' : ''}',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            AppSpacing.gapVerticalMD,
            Text(
              'Belum Ada Data Pengiriman',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            AppSpacing.gapVerticalSM,
            Padding(
              padding: AppSpacing.paddingHorizontalMD,
              child: Text(
                'Silakan ketik atau scan nomor resi pesanan di kolom pencarian di atas untuk memuat rincian pesanan.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BarcodeScannerPage()),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _receiptController.text = scannedCode;
      });
      _searchOrder();
    }
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  MobileScannerController? _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      _hasScanned = true;
      Navigator.pop(context, barcode.rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Resi / Barcode / QR'),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller!,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => _controller!.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.surface, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke QR code atau Barcode resi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.surface.withValues(alpha: 0.8),
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
