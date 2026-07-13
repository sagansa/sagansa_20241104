import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/constants.dart';

/// Model data resi/stiker yang akan dicetak.
class StickerData {
  final String receiptNo;
  final String storeName;
  final String providerName;
  final String deliveryServiceName;
  final String? deliveryDate;
  final String? receiverName;
  final List<StickerItem> items;

  const StickerData({
    required this.receiptNo,
    required this.storeName,
    required this.providerName,
    required this.deliveryServiceName,
    this.deliveryDate,
    this.receiverName,
    this.items = const [],
  });

  /// Membuat [StickerData] dari Map order hasil API.
  factory StickerData.fromOrderMap(Map<String, dynamic> order) {
    final itemsRaw = order['items'] as List<dynamic>? ?? [];
    return StickerData(
      receiptNo: order['receipt_no']?.toString() ?? '-',
      storeName: order['store_name']?.toString() ?? '-',
      providerName: order['provider_name']?.toString() ?? '-',
      deliveryServiceName: order['delivery_service_name']?.toString() ?? '-',
      deliveryDate: order['delivery_date']?.toString(),
      receiverName: order['received_by']?.toString(),
      items: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map((item) => StickerItem(
                productName: item['product_name']?.toString() ?? '-',
                quantity: item['quantity']?.toString() ?? '0',
                unit: item['product_unit']?.toString(),
              ))
          .toList(),
    );
  }
}

class StickerItem {
  final String productName;
  final String quantity;
  final String? unit;

  const StickerItem({
    required this.productName,
    required this.quantity,
    this.unit,
  });
}

/// Exception khusus untuk error koneksi ke thermal printer.
class PrinterConnectionException implements Exception {
  final String message;
  PrinterConnectionException(this.message);

  @override
  String toString() => message;
}

/// Service untuk mencetak resi berbentuk stiker melalui thermal printer.
///
/// Printer dihubungkan melalui **WiFi/jaringan** menggunakan ESC/POS over TCP
/// (umumnya port 9100). Sebagai fallback tersedia juga pencetakan via PDF
/// spooler sistem (`printing`) dengan ukuran stiker khusus.
class ThermalPrinterService {
  ThermalPrinterService._();
  static final ThermalPrinterService instance = ThermalPrinterService._();

  Socket? _socket;

  // ---------------------------------------------------------------------------
  // Network (WiFi) connection management
  // ---------------------------------------------------------------------------

  /// Mengecek apakah printer dapat dijangkau dengan membuka koneksi TCP.
  ///
  /// Mengembalikan true bila koneksi berhasil dibuka dalam batas timeout.
  Future<bool> testConnection({
    required String ip,
    required int port,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(milliseconds: PrinterConstants.connectTimeoutMs),
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ThermalPrinterService.testConnection: $e');
      }
      return false;
    } finally {
      socket?.destroy();
    }
  }

  /// Mengecek apakah ada koneksi aktif (socket terbuka) ke printer.
  bool get hasActiveConnection => _socket != null;

  /// Membuka koneksi TCP ke thermal printer dan menyimpannya untuk dipakai
  /// berulang oleh [printStickerViaWifi].
  Future<void> connect({
    required String ip,
    required int port,
  }) async {
    // Tutup koneksi lama dulu bila ada.
    await disconnect();

    _socket = await Socket.connect(
      ip,
      port,
      timeout: Duration(milliseconds: PrinterConstants.connectTimeoutMs),
    );
  }

  /// Menutup koneksi TCP ke thermal printer.
  Future<void> disconnect() async {
    final s = _socket;
    _socket = null;
    try {
      await s?.close();
    } catch (_) {
      // ignore
    }
  }

  // ---------------------------------------------------------------------------
  // Sticker generation (PDF)
  // ---------------------------------------------------------------------------

  /// Menghasilkan dokumen PDF stiker dengan dimensi khusus (mm).
  ///
  /// Digunakan untuk preview maupun pencetakan melalui print spooler sistem
  /// (jika tidak ada thermal printer WiFi yang terhubung).
  pw.Document buildStickerPdf({
    required StickerData data,
    required double widthMm,
    required double heightMm,
    double fontSize = 10,
  }) {
    final pageFormat = PdfPageFormat(
      widthMm * PdfPageFormat.mm,
      heightMm * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(0),
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: _buildStickerContent(data, fontSize),
          );
        },
      ),
    );

    return doc;
  }

  /// Mencetak stiker melalui print spooler sistem (PDF).
  ///
  /// Cocok ketika thermal printer WiFi tidak tersedia / tidak dikonfigurasi,
  /// atau ketika user ingin memilih printer lain dari dialog sistem.
  Future<bool> printStickerViaSpooler({
    required StickerData data,
    required double widthMm,
    required double heightMm,
    double fontSize = 10,
    String docName = 'resi-stiker',
  }) async {
    try {
      final doc = buildStickerPdf(
        data: data,
        widthMm: widthMm,
        heightMm: heightMm,
        fontSize: fontSize,
      );

      return await Printing.layoutPdf(
        name: docName,
        onLayout: (_) async => doc.save(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ThermalPrinterService.printStickerViaSpooler: $e');
      }
      return false;
    }
  }

  /// Mencetak stiker langsung ke thermal printer via WiFi (ESC/POS over TCP).
  ///
  /// Bila [connect] belum dipanggil sebelumnya, method ini akan membuka koneksi
  /// ephemeral lalu menutupnya setelah selesai. Mencetak sesuai [copies].
  Future<bool> printStickerViaWifi({
    required StickerData data,
    required String ip,
    required int port,
    required int copies,
    bool keepConnection = false,
  }) async {
    Socket? socket;
    final bool ownsSocket = !hasActiveConnection;

    try {
      socket = ownsSocket
          ? await Socket.connect(
              ip,
              port,
              timeout: Duration(milliseconds: PrinterConstants.connectTimeoutMs),
            )
          : _socket;

      if (socket == null) {
        throw PrinterConnectionException(
          'Belum ada koneksi ke printer. Panggil connect() terlebih dahulu.',
        );
      }

      final bytes = _buildEscPosBytes(data);

      for (var i = 0; i < copies; i++) {
        socket.add(bytes);
      }

      await socket.flush();

      return true;
    } on SocketException catch (e) {
      throw PrinterConnectionException(
        'Gagal terhubung ke printer $ip:$port. ${e.message}. Periksa IP/port '
        'dan jaringan WiFi.',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ThermalPrinterService.printStickerViaWifi: $e');
      }
      throw PrinterConnectionException('Gagal mencetak stiker: $e');
    } finally {
      // Bila socket dibuka di method ini, tutup setelah selesai.
      if (ownsSocket && socket != null) {
        try {
          await socket.close();
        } catch (_) {
          // ignore
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Internal builders
  // ---------------------------------------------------------------------------

  /// Membangun konten visual stiker untuk PDF.
  pw.Widget _buildStickerContent(StickerData data, double fontSize) {
    final baseStyle = pw.TextStyle(fontSize: fontSize);
    final boldStyle = pw.TextStyle(
      fontSize: fontSize + 2,
      fontWeight: pw.FontWeight.bold,
    );
    final labelStyle = pw.TextStyle(
      fontSize: fontSize - 1,
      color: PdfColors.grey600,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Text('RESI PENGIRIMAN', style: boldStyle),
        ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
        // Info utama
        _stickerRow('No. Resi', data.receiptNo, baseStyle, labelStyle),
        _stickerRow('Toko', data.storeName, baseStyle, labelStyle),
        _stickerRow('Provider', data.providerName, baseStyle, labelStyle),
        _stickerRow(
            'Jasa Kirim', data.deliveryServiceName, baseStyle, labelStyle),
        if (data.deliveryDate != null && data.deliveryDate!.isNotEmpty)
          _stickerRow(
              'Tgl. Kirim', data.deliveryDate!, baseStyle, labelStyle),
        if (data.receiverName != null && data.receiverName!.isNotEmpty)
          _stickerRow('Penerima', data.receiverName!, baseStyle, labelStyle),
        // Items
        if (data.items.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('Detail Produk:', style: boldStyle),
          pw.SizedBox(height: 2),
          ...data.items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1),
              child: pw.Text(
                '• ${item.productName} x ${item.quantity}'
                '${item.unit != null ? ' ${item.unit}' : ''}',
                style: baseStyle,
              ),
            ),
          ),
        ],
        pw.Spacer(),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'SAGANSA',
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _stickerRow(
    String label,
    String value,
    pw.TextStyle valueStyle,
    pw.TextStyle labelStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(label, style: labelStyle),
          ),
          pw.Expanded(child: pw.Text(value, style: valueStyle)),
        ],
      ),
    );
  }

  /// Membangun ESC/POS byte commands untuk thermal printer.
  ///
  /// Catatan: ESC/POS cocok untuk printer 58mm / 80mm standar. Untuk sticker
  /// berukuran besar (mis. 100mm) layout ini tetap bisa dipakai namun tampilan
  /// dapat berbeda antar merek printer.
  List<int> _buildEscPosBytes(StickerData data) {
    final List<int> bytes = <int>[];

    // Init printer
    bytes.addAll([0x1B, 0x40]);

    // Header — center + double height/width
    bytes.addAll([0x1B, 0x61, 0x01]); // align center
    bytes.addAll([0x1D, 0x21, 0x11]); // double width + height
    bytes.addAll(utf8.encode('RESI PENGIRIMAN\n'));
    bytes.addAll([0x1D, 0x21, 0x00]); // normal size

    // Separator
    bytes.addAll([0x1B, 0x61, 0x01]); // center
    bytes.addAll(utf8.encode('${'-' * 32}\n'));

    // Detail — left align
    bytes.addAll([0x1B, 0x61, 0x00]); // align left
    bytes.addAll(_escPosLine('No. Resi', data.receiptNo));
    bytes.addAll(_escPosLine('Toko', data.storeName));
    bytes.addAll(_escPosLine('Provider', data.providerName));
    bytes.addAll(_escPosLine('Jasa Kirim', data.deliveryServiceName));
    if (data.deliveryDate != null && data.deliveryDate!.isNotEmpty) {
      bytes.addAll(_escPosLine('Tgl. Kirim', data.deliveryDate!));
    }
    if (data.receiverName != null && data.receiverName!.isNotEmpty) {
      bytes.addAll(_escPosLine('Penerima', data.receiverName!));
    }

    // Items
    if (data.items.isNotEmpty) {
      bytes.addAll([0x0A]); // feed
      bytes.addAll(utf8.encode('Detail Produk:\n'));
      for (final item in data.items) {
        final unit = item.unit != null ? ' ${item.unit}' : '';
        bytes.addAll(
            utf8.encode('  • ${item.productName} x ${item.quantity}$unit\n'));
      }
    }

    // Footer
    bytes.addAll([0x0A]); // feed
    bytes.addAll([0x1B, 0x61, 0x01]); // center
    bytes.addAll(utf8.encode('${'-' * 32}\n'));
    bytes.addAll(utf8.encode('SAGANSA\n'));

    // Feed + cut
    bytes.addAll([0x0A, 0x0A, 0x0A]); // feed 3 lines
    bytes.addAll([0x1D, 0x56, 0x00]); // full cut

    return bytes;
  }

  /// Helper: membuat satu baris "label: value\n" dalam bytes.
  List<int> _escPosLine(String label, String value) {
    return utf8.encode('$label: $value\n');
  }
}