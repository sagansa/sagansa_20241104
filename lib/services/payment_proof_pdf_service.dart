import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/enums/order_mode.dart';
import 'presence_service.dart';

class PaymentProofPdfService {
  final PresenceService _presenceService;

  PaymentProofPdfService({PresenceService? presenceService})
      : _presenceService = presenceService ?? PresenceService();

  Future<Uint8List> _downloadImageBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat gambar bukti pembayaran.');
    }
    return response.bodyBytes;
  }

  Future<void> printPaymentProofs(
    List<Map<String, dynamic>> orders,
    OrderMode orderMode, {
    required bool requirePending,
  }) async {
    final printableOrders = orders.where((order) {
      final imageUrl = order['image_payment_url']?.toString();
      if (imageUrl == null || imageUrl.trim().isEmpty) {
        return false;
      }
      if (requirePending && order['delivery_status'] != 1) {
        return false;
      }
      return true;
    }).toList();

    if (printableOrders.isEmpty) {
      throw Exception(
        requirePending
            ? 'Tidak ada bukti pembayaran status belum dikirim untuk dicetak.'
            : 'Tidak ada bukti pembayaran untuk dicetak.',
      );
    }

    final document = pw.Document();
    final printedOrderIds = <int>[];
    final failedReceipts = <String>[];

    for (final order in printableOrders) {
      try {
        final imageBytes = await _downloadImageBytes(order['image_payment_url'].toString());
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
                              orderMode.isOnline
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
                            if (orderMode.isOnline)
                              pw.Text('Provider: ${order['provider_name'] ?? '-'}')
                            else ...[
                              pw.Text('Metode Bayar: ${order['payment_method'] ?? '-'}'),
                              if (order['bank_name'] != null)
                                pw.Text('Rekening: ${order['bank_name']} - ${order['bank_account_number']}'),
                            ],
                            pw.Text('Jasa Kirim: ${order['delivery_service_name'] ?? '-'}'),
                            pw.Text('Tanggal Kirim: ${order['delivery_date'] ?? '-'}'),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      name: orderMode.isOnline
          ? 'bukti-pembayaran-online.pdf'
          : 'bukti-pembayaran-direct.pdf',
      onLayout: (_) async => document.save(),
    );

    if (printCompleted && printedOrderIds.isNotEmpty) {
      await _presenceService.markPaymentProofsPrinted(
        orderIds: printedOrderIds,
      );
    }

    return;
  }
}
