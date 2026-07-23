import '../providers/printer_provider.dart';
import '../services/thermal_printer_service.dart';

class StickerPrintOrchestrator {
  final ThermalPrinterService thermalService;

  StickerPrintOrchestrator({
    ThermalPrinterService? thermalService,
  }) : thermalService = thermalService ?? ThermalPrinterService.instance;

  Future<StickerPrintResult> printSticker(
    Map<String, dynamic> order,
    PrinterProvider printerProvider,
  ) async {
    final data = StickerData.fromOrderMap(order);

    if (printerProvider.isEnabled) {
      final ok = await thermalService.printStickerViaWifi(
        data: data,
        ip: printerProvider.ip,
        port: printerProvider.port,
        copies: printerProvider.copies,
      );
      return StickerPrintResult(
        success: ok,
        message: ok
            ? 'Stiker dicetak via WiFi (${printerProvider.formattedEndpoint}, '
                '${printerProvider.copies}x).'
            : 'Gagal mencetak stiker via WiFi.',
        orderId: int.tryParse(order['id']?.toString() ?? ''),
      );
    } else {
      final ok = await thermalService.printStickerViaSpooler(
        data: data,
        widthMm: printerProvider.widthMm,
        heightMm: printerProvider.heightMm,
        fontSize: printerProvider.fontSize,
        docName: 'resi-stiker-${order['receipt_no'] ?? ''}',
      );
      return StickerPrintResult(
        success: ok,
        message: ok
            ? 'Stiker dikirim ke spooler (${printerProvider.formattedSize}).'
            : 'Gagal mencetak stiker.',
        orderId: int.tryParse(order['id']?.toString() ?? ''),
      );
    }
  }
}

class StickerPrintResult {
  final bool success;
  final String message;
  final int? orderId;

  const StickerPrintResult({
    required this.success,
    required this.message,
    this.orderId,
  });
}
