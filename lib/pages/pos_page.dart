import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_detail_page.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _PosPageState();
}

class _PosPageState extends State<POSPage> {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  String _userName = '';
  String _storeName = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadUserAndStoreInfo();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _productService.getProducts();
      setState(() {
        _products = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading products: $e');
    }
  }

  Future<void> _loadUserAndStoreInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      print('Raw user string from SharedPreferences: $userString');

      if (userString != null) {
        final userData = json.decode(userString) as Map<String, dynamic>;
        final companyData = userData['company'] as Map<String, dynamic>;

        setState(() {
          _userName = userData['name'] ?? 'User';
          _storeName = companyData['name'] ?? 'Store';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _userName = 'User';
        _storeName = 'Store';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _storeName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Riwayat Transaksi'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.pushNamed(context, '/transaction-history');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Konfirmasi Logout'),
                    content: Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Implementasi logout
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear(); // Hapus semua data lokal

                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          }
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POS System',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              _storeName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartPage(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    if (cart.cartCount == 0) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.cartCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildGridItem(product);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildListItem(product);
      },
    );
  }

  Widget _buildGridItem(ProductModel product) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: product.image?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: product.image!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) =>
                        const _DefaultProductImage(),
                  )
                : const _DefaultProductImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productId: product.id,
              ),
            ),
          );
        },
        leading: SizedBox(
          width: 56,
          height: 56,
          child: product.image?.isNotEmpty == true
              ? CachedNetworkImage(
                  imageUrl: product.image!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const _DefaultProductImage(),
                )
              : const _DefaultProductImage(),
        ),
        title: Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }

  String formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}

class _DefaultProductImage extends StatelessWidget {
  const _DefaultProductImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
