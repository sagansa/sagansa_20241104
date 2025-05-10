import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/store_service.dart';
import '../models/store_model.dart';
import 'pos_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final StoreService _storeService = StoreService();
  List<StoreModel> stores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final result = await _storeService.getStores();
      setState(() {
        stores = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading stores: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi anda telah berakhir. Silakan login kembali'),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _selectStore(StoreModel store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('store_id', store.id.toString());
      await prefs.setString('store_name', store.nickname);

      print('Store selected - ID: ${store.id}, Name: ${store.nickname}');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => POSPage()),
        (route) => false,
      );
    } catch (e) {
      print('Error selecting store: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih toko: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Toko'),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stores.isEmpty
              ? const Center(child: Text('Tidak ada toko tersedia'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Card(
                      child: ListTile(
                        title: Text(store.nickname),
                        onTap: () => _selectStore(store),
                      ),
                    );
                  },
                ),
    );
  }
}
