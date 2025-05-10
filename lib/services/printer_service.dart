import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_detail_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterService {
  static const String _key = 'printers';

  // Menyimpan list printer
  static Future<void> savePrinters(List<Map<String, dynamic>> printers) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(printers);
    await prefs.setString(_key, encodedData);
  }

  // Mengambil list printer
  static Future<List<Map<String, dynamic>>> getPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_key);

    if (encodedData != null) {
      final List<dynamic> decodedData = json.decode(encodedData);
      return decodedData.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List?> getBondedDevices() async {
    try {
      final List? devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      print('Error getting bonded devices: $e');
      return [];
    }
  }

  Future<bool> connectPrinter(String address) async {
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: address);
      return result;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  Future<bool> isConnected() async {
    final bool? status = await PrintBluetoothThermal.connectionStatus;
    return status ?? false;
  }

  Future<void> printReceipt(TransactionDetail transaction) async {
    try {
      // Request bluetooth permissions
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();

      if (!bluetoothScan.isGranted || !bluetoothConnect.isGranted) {
        throw Exception('Izin Bluetooth diperlukan untuk mencetak');
      }

      // Generate receipt content
      final List<int> bytes = await _generateReceiptContent(transaction);

      // Print
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      if (!result) {
        throw Exception('Gagal mencetak struk');
      }
    } catch (e) {
      print('Error printing receipt: $e');
      throw Exception('Gagal mencetak: $e');
    }
  }

  Future<List<int>> _generateReceiptContent(
      TransactionDetail transaction) async {
    // Initialize printer
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    try {
      // Header
      bytes += generator.reset();
      bytes += generator.text('SAGANSA POS',
          styles: const PosStyles(
              align: PosAlign.center, bold: true, height: PosTextSize.size2));

      if (transaction.store != null) {
        bytes += generator.text(transaction.store!.name,
            styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.hr();

      // Transaction info
      bytes += generator.text('No: ${transaction.transactionNumber}',
          styles: const PosStyles(bold: true));
      bytes += generator.text(
          'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction.createdAt))}');

      if (transaction.customer != null) {
        bytes += generator.text('Customer: ${transaction.customer!.name}');
      }

      bytes += generator.hr();

      // Items
      for (var item in transaction.items) {
        // Product name
        bytes += generator.text(item.productName,
            styles: const PosStyles(bold: true));

        // Variant and modifiers
        if (item.variant != null) {
          bytes += generator.text('  ${item.variant!.name}',
              styles: const PosStyles(width: PosTextSize.size1));
        }

        if (item.modifier != null && item.modifier!.isNotEmpty) {
          for (var mod in item.modifier!) {
            bytes += generator.text('  ${mod.name}: ${mod.detail.name}',
                styles: const PosStyles(width: PosTextSize.size1));
          }
        }

        // Quantity and price
        bytes += generator.row([
          PosColumn(
            text: '${item.quantity}x ${_formatPrice(item.price)}',
            width: 6,
          ),
          PosColumn(
            text: _formatPrice(item.subtotal),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        bytes += generator.text(''); // Spacing between items
      }

      bytes += generator.hr();

      // Payment details
      bytes += generator.row([
        PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: _formatPrice(transaction.totalAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Bayar', width: 6),
        PosColumn(
          text: _formatPrice(transaction.paidAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Kembali', width: 6),
        PosColumn(
          text: _formatPrice(transaction.changeAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Footer
      bytes += generator.hr();
      bytes += generator.text('Terima kasih atas kunjungan Anda',
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Powered by SAGANSA',
          styles: const PosStyles(
              align: PosAlign.center, width: PosTextSize.size1));

      bytes += generator.feed(3);
      bytes += generator.cut();

      return bytes;
    } catch (e) {
      print('Error generating receipt content: $e');
      throw Exception('Gagal membuat konten struk: $e');
    }
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  static Future<void> connectAndPrint(Map<String, dynamic> printer) async {
    // Implementasi logika untuk menghubungkan dan mencetak menggunakan printer
    // Contoh:
    print('Connecting to printer: ${printer['name']}');
    // Lakukan koneksi dan pencetakan di sini
  }

  Future<List<BluetoothInfo>> getBluetoots() async {
    // Gunakan pairedBluetooths bukan bluetooths
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;
    return listResult;
  }
}
