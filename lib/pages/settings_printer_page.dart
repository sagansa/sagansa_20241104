import 'package:flutter/material.dart';
import '../services/printer_service.dart';
import 'settings_printer_form_page.dart';

class SettingsPrinterPage extends StatefulWidget {
  const SettingsPrinterPage({super.key});

  @override
  State<SettingsPrinterPage> createState() => _SettingsPrinterPageState();
}

class _SettingsPrinterPageState extends State<SettingsPrinterPage> {
  List<Map<String, dynamic>> _printers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);
    try {
      final printers = await PrinterService.getPrinters();
      setState(() {
        _printers = printers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrinters() async {
    try {
      await PrinterService.savePrinters(_printers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllPrinters() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Printer'),
        content: const Text(
            'Anda yakin ingin menghapus semua printer? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() {
          _printers.clear();
        });
        await _savePrinters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua printer berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus printer: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          if (_printers.isNotEmpty) // Hanya tampilkan jika ada printer
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Hapus Semua Printer',
              onPressed: _deleteAllPrinters,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _printers.isEmpty
                ? const Center(
                    child: Text('Belum ada printer yang ditambahkan'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _printers.length,
                    itemBuilder: (context, index) {
                      final printer = _printers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(printer['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(printer['model']),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (printer['printReceiptAndBills'])
                                    _buildTag('Struk & Tagihan'),
                                  if (printer['printOrders'])
                                    _buildTag('Pesanan'),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editPrinter(printer),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_printers
                    .isNotEmpty) // Tambahkan tombol hapus semua di bawah
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton.icon(
                      onPressed: _deleteAllPrinters,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Hapus Semua Printer'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _addPrinter,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Printer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _addPrinter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrinterFormPage()),
    );

    if (result != null && result['action'] == 'add') {
      setState(() {
        // Tambahkan ID unik untuk printer baru
        final newPrinter = result['data'];
        newPrinter['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        _printers.add(newPrinter);
      });
      await _savePrinters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer berhasil ditambahkan')),
        );
      }
    }
  }

  Future<void> _editPrinter(Map<String, dynamic> printer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterFormPage(printerData: printer),
      ),
    );

    if (result != null) {
      if (result['action'] == 'edit') {
        setState(() {
          final index = _printers.indexWhere((p) => p['id'] == printer['id']);
          if (index != -1) {
            _printers[index] = result['data'];
          }
        });
        await _savePrinters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Printer berhasil diperbarui')),
          );
        }
      } else if (result['action'] == 'delete') {
        setState(() {
          _printers.removeWhere((p) => p['id'] == printer['id']);
        });
        await _savePrinters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Printer berhasil dihapus')),
          );
        }
      }
    }
  }
}
