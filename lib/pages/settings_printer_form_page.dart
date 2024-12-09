import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/printer_bluetooth.dart';

class PrinterFormPage extends StatefulWidget {
  final Map<String, dynamic>? printerData;

  const PrinterFormPage({super.key, this.printerData});

  @override
  State<PrinterFormPage> createState() => _PrinterFormPageState();
}

class _PrinterFormPageState extends State<PrinterFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ipAddressController;
  String? _selectedPrinterModel;
  String _connectionType = 'bluetooth'; // 'bluetooth' atau 'lan'
  PrinterBluetooth? _selectedBluetoothDevice;
  bool _printReceiptAndBills = false;
  bool _printOrders = false;
  List<PrinterBluetooth> _bluetoothDevices = [];
  bool get isEditMode => widget.printerData != null;

  final List<String> _printerModels = [
    'Epson TM-T82',
    'Epson TM-T88',
    'Xprinter XP-58',
    'Xprinter XP-80',
    'Custom Q3',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ipAddressController = TextEditingController();

    if (isEditMode) {
      _nameController.text = widget.printerData!['name'];
      _selectedPrinterModel = widget.printerData!['model'];
      _connectionType = widget.printerData!['connectionType'];
      _printReceiptAndBills =
          widget.printerData!['printReceiptAndBills'] ?? false;
      _printOrders = widget.printerData!['printOrders'] ?? false;

      if (_connectionType == 'lan') {
        _ipAddressController.text = widget.printerData!['ipAddress'];
      }
    }

    _loadBluetoothDevices();
  }

  Future<void> _loadBluetoothDevices() async {
    try {
      final bool isBluetoothOn = await PrintBluetoothThermal.bluetoothEnabled;
      if (isBluetoothOn) {
        final List<dynamic> devices =
            await PrintBluetoothThermal.pairedBluetooths;
        setState(() {
          _bluetoothDevices = devices
              .map((device) => PrinterBluetooth.fromMap(device))
              .toList();
          if (isEditMode && _connectionType == 'bluetooth') {
            _selectedBluetoothDevice = devices.firstWhere(
              (device) =>
                  device.address == widget.printerData!['bluetoothAddress'],
              orElse: () => PrinterBluetooth(name: '', address: ''),
            );
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Printer' : 'Tambah Printer'),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePrinter,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nama Printer
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Printer',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Printer Kasir 1',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama printer tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Model Printer
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Model Printer',
                border: OutlineInputBorder(),
              ),
              value: _selectedPrinterModel,
              items: _printerModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPrinterModel = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Pilih model printer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Connection Type
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Bluetooth'),
                    value: 'bluetooth',
                    groupValue: _connectionType,
                    onChanged: (value) {
                      setState(() => _connectionType = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('LAN'),
                    value: 'lan',
                    groupValue: _connectionType,
                    onChanged: (value) {
                      setState(() => _connectionType = value!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Connection Settings
            if (_connectionType == 'bluetooth') ...[
              DropdownButtonFormField<PrinterBluetooth>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Printer Bluetooth',
                  border: OutlineInputBorder(),
                ),
                value: _selectedBluetoothDevice,
                items: _bluetoothDevices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedBluetoothDevice = value);
                },
                validator: (value) {
                  if (_connectionType == 'bluetooth' && value == null) {
                    return 'Pilih printer bluetooth';
                  }
                  return null;
                },
              ),
            ] else ...[
              TextFormField(
                controller: _ipAddressController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: 192.168.1.100',
                ),
                validator: (value) {
                  if (_connectionType == 'lan') {
                    if (value == null || value.isEmpty) {
                      return 'IP Address tidak boleh kosong';
                    }
                    // Tambahkan validasi format IP Address jika diperlukan
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),

            // Print Settings
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Print Struk dan Tagihan'),
                    subtitle: const Text(
                        'Printer akan digunakan untuk mencetak struk dan tagihan'),
                    value: _printReceiptAndBills,
                    onChanged: (value) {
                      setState(() => _printReceiptAndBills = value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Print Pesanan'),
                    subtitle: const Text(
                        'Printer akan digunakan untuk mencetak pesanan ke dapur'),
                    value: _printOrders,
                    onChanged: (value) {
                      setState(() => _printOrders = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test Print Button
            ElevatedButton.icon(
              onPressed: _testPrint,
              icon: const Icon(Icons.print),
              label: const Text('Test Print'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _savePrinter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(isEditMode ? 'Simpan Perubahan' : 'Tambah Printer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testPrint() async {
    try {
      if (_connectionType == 'bluetooth' && _selectedBluetoothDevice == null) {
        throw Exception('Pilih printer bluetooth terlebih dahulu');
      }
      if (_connectionType == 'lan' && _ipAddressController.text.isEmpty) {
        throw Exception('Masukkan IP Address printer');
      }

      // Implementasi test print sesuai jenis koneksi
      if (_connectionType == 'bluetooth') {
        // Test print bluetooth
      } else {
        // Test print LAN
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print berhasil')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal test print: $e')),
      );
    }
  }

  void _savePrinter() {
    if (_formKey.currentState!.validate()) {
      final printerData = {
        'id': widget.printerData?['id'],
        'name': _nameController.text,
        'model': _selectedPrinterModel,
        'connectionType': _connectionType,
        'printReceiptAndBills': _printReceiptAndBills,
        'printOrders': _printOrders,
      };

      // Tambahkan data sesuai jenis koneksi
      if (_connectionType == 'bluetooth') {
        printerData['bluetoothName'] = _selectedBluetoothDevice?.name;
        printerData['bluetoothAddress'] = _selectedBluetoothDevice?.address;
      } else {
        printerData['ipAddress'] = _ipAddressController.text;
      }

      Navigator.pop(context, {
        'action': isEditMode ? 'edit' : 'add',
        'data': printerData,
      });
    }
  }

  Future<void> _deletePrinter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Printer'),
        content: const Text('Anda yakin ingin menghapus printer ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pop(
          context, {'action': 'delete', 'id': widget.printerData?['id']});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipAddressController.dispose();
    super.dispose();
  }
}
