import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Model sederhana untuk merepresentasikan thermal printer yang dihubungkan
/// melalui jaringan WiFi (TCP/IP).
class ThermalPrinterDevice {
  final String ip;
  final int port;
  final String name;

  const ThermalPrinterDevice({
    required this.ip,
    required this.port,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThermalPrinterDevice && ip == other.ip && port == other.port;

  @override
  int get hashCode => Object.hash(ip, port);

  @override
  String toString() => 'ThermalPrinterDevice($name, $ip:$port)';
}

/// Provider yang menyimpan konfigurasi printer thermal untuk cetak stiker.
///
/// Printer thermal terhubung melalui jaringan WiFi (ESC/POS over TCP, umumnya
/// port 9100). Konfigurasi disimpan di SharedPreferences.
class PrinterProvider extends ChangeNotifier {
  PrinterProvider() {
    _load();
  }

  bool _isLoaded = false;
  bool _isEnabled = false;
  double _widthMm = PrinterConstants.defaultWidthMm;
  double _heightMm = PrinterConstants.defaultHeightMm;
  int _copies = PrinterConstants.defaultCopies;
  double _fontSize = PrinterConstants.defaultFontSize;
  String _ip = PrinterConstants.defaultIp;
  int _port = PrinterConstants.defaultPort;
  String _name = 'Thermal Printer';
  bool _isConnected = false;

  bool get isLoaded => _isLoaded;
  bool get isEnabled => _isEnabled;

  double get widthMm => _widthMm;
  double get heightMm => _heightMm;
  int get copies => _copies;
  double get fontSize => _fontSize;
  String get ip => _ip;
  int get port => _port;
  String get name => _name;
  bool get isConnected => _isConnected;

  /// Device yang terkonfigurasi (IP + port + nama).
  ThermalPrinterDevice get device => ThermalPrinterDevice(
        ip: _ip,
        port: _port,
        name: _name,
      );

  /// Ukuran stiker yang sudah diformat agar mudah ditampilkan (mis. "100 x 150 mm").
  String get formattedSize =>
      '${_widthMm.toStringAsFixed(0)} x ${_heightMm.toStringAsFixed(0)} mm';

  /// Endpoint jaringan yang sudah diformat (mis. "192.168.1.100:9100").
  String get formattedEndpoint => '$_ip:$_port';

  /// Memuat konfigurasi dari SharedPreferences.
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isEnabled = prefs.getBool(PrinterConstants.thermalEnabledKey) ?? false;
      _widthMm = _clampDouble(
        prefs.getDouble(PrinterConstants.thermalWidthMmKey),
        PrinterConstants.defaultWidthMm,
        PrinterConstants.minWidthMm,
        PrinterConstants.maxWidthMm,
      );
      _heightMm = _clampDouble(
        prefs.getDouble(PrinterConstants.thermalHeightMmKey),
        PrinterConstants.defaultHeightMm,
        PrinterConstants.minHeightMm,
        PrinterConstants.maxHeightMm,
      );

      _ip = prefs.getString(PrinterConstants.thermalIpKey) ??
          PrinterConstants.defaultIp;
      _port = prefs.getInt(PrinterConstants.thermalPortKey) ??
          PrinterConstants.defaultPort;
      _name = prefs.getString(PrinterConstants.thermalNameKey) ??
          'Thermal Printer';

      final storedCopies = prefs.getInt(PrinterConstants.thermalCopiesKey);
      _copies = storedCopies == null
          ? PrinterConstants.defaultCopies
          : storedCopies.clamp(
              PrinterConstants.minCopies,
              PrinterConstants.maxCopies,
            );

      _fontSize = _clampDouble(
        prefs.getDouble(PrinterConstants.thermalFontSizeKey),
        PrinterConstants.defaultFontSize,
        PrinterConstants.minFontSize,
        PrinterConstants.maxFontSize,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PrinterProvider: gagal memuat konfigurasi: $e');
      }
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Memuat ulang konfigurasi dari storage (mis. setelah diubah dari halaman lain).
  Future<void> reload() => _load();

  Future<void> setEnabled(bool value) async {
    if (_isEnabled == value) return;
    _isEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrinterConstants.thermalEnabledKey, value);
  }

  Future<void> setSize({
    required double widthMm,
    required double heightMm,
  }) async {
    final newWidth = widthMm.clamp(
      PrinterConstants.minWidthMm,
      PrinterConstants.maxWidthMm,
    );
    final newHeight = heightMm.clamp(
      PrinterConstants.minHeightMm,
      PrinterConstants.maxHeightMm,
    );

    if (newWidth == _widthMm && newHeight == _heightMm) return;

    _widthMm = newWidth;
    _heightMm = newHeight;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PrinterConstants.thermalWidthMmKey, _widthMm);
    await prefs.setDouble(PrinterConstants.thermalHeightMmKey, _heightMm);
  }

  Future<void> setCopies(int value) async {
    final newCopies = value.clamp(
      PrinterConstants.minCopies,
      PrinterConstants.maxCopies,
    );
    if (newCopies == _copies) return;

    _copies = newCopies;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrinterConstants.thermalCopiesKey, _copies);
  }

  Future<void> setFontSize(double value) async {
    final newSize = value.clamp(
      PrinterConstants.minFontSize,
      PrinterConstants.maxFontSize,
    );
    if (newSize == _fontSize) return;

    _fontSize = newSize;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PrinterConstants.thermalFontSizeKey, _fontSize);
  }

  Future<void> setNetwork({
    required String ip,
    required int port,
    String? name,
  }) async {
    final newIp = ip.trim();
    final newPort = port;
    final newName = name?.trim().isNotEmpty == true ? name!.trim() : _name;

    if (newIp == _ip && newPort == _port && newName == _name) return;

    _ip = newIp;
    _port = newPort;
    _name = newName;
    // Saat endpoint berubah, anggap belum terhubung.
    _isConnected = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrinterConstants.thermalIpKey, _ip);
    await prefs.setInt(PrinterConstants.thermalPortKey, _port);
    await prefs.setString(PrinterConstants.thermalNameKey, _name);
  }

  /// Menandai status koneksi ke printer (diupdate oleh service setelah test).
  void setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    notifyListeners();
  }

  /// Hapus seluruh konfigurasi printer thermal (dipakai pada reset/logout bila diperlukan).
  Future<void> reset() async {
    _isEnabled = false;
    _widthMm = PrinterConstants.defaultWidthMm;
    _heightMm = PrinterConstants.defaultHeightMm;
    _copies = PrinterConstants.defaultCopies;
    _fontSize = PrinterConstants.defaultFontSize;
    _ip = PrinterConstants.defaultIp;
    _port = PrinterConstants.defaultPort;
    _name = 'Thermal Printer';
    _isConnected = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrinterConstants.thermalEnabledKey);
    await prefs.remove(PrinterConstants.thermalWidthMmKey);
    await prefs.remove(PrinterConstants.thermalHeightMmKey);
    await prefs.remove(PrinterConstants.thermalIpKey);
    await prefs.remove(PrinterConstants.thermalPortKey);
    await prefs.remove(PrinterConstants.thermalNameKey);
    await prefs.remove(PrinterConstants.thermalCopiesKey);
    await prefs.remove(PrinterConstants.thermalFontSizeKey);
  }

  double _clampDouble(
    double? value,
    double fallback,
    double min,
    double max,
  ) {
    if (value == null) return fallback;
    return value.clamp(min, max);
  }
}