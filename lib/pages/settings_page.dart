import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Printer Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Printer'),
              subtitle: const Text('Pengaturan printer struk dan dapur'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                print('Navigating to printer settings...');
                Navigator.pushNamed(context, '/settings/printer');
              },
            ),
          ),
          const SizedBox(height: 8),

          // General Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Umum'),
              subtitle: const Text('Tampilan, bahasa, dan pengaturan dasar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {}, // Tambahkan route ke halaman pengaturan umum
            ),
          ),
          const SizedBox(height: 8),

          // Payment Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Pembayaran'),
              subtitle: const Text('Metode pembayaran dan integrasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {}, // Tambahkan route ke halaman pengaturan pembayaran
            ),
          ),
          const SizedBox(height: 8),

          // Store Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Toko'),
              subtitle: const Text('Informasi toko dan pajak'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {}, // Tambahkan route ke halaman pengaturan toko
            ),
          ),
          const SizedBox(height: 8),

          // Other Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.more_horiz),
              title: const Text('Lainnya'),
              subtitle: const Text('Backup, keamanan, dan pengaturan tambahan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {}, // Tambahkan route ke halaman pengaturan lainnya
            ),
          ),
        ],
      ),
    );
  }
}
