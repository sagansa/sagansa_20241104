import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';
import 'product_detail_page.dart';
import 'cart_page.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'transaction_history_page.dart';
import '../models/product_model.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class POSPage extends StatefulWidget {
  @override
  _POSPageState createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  bool isGridView = true;
  String selectedCategory = 'Semua';
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  String userName = 'Nama Kasir';
  String storeName = '-';
  final ProductService _productService = ProductService();
  List<CategoryModel> _categories = [];
  List<ProductModel> products = [];
  int cartCount = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Print semua keys dan values yang tersimpan
      print('=== Shared Preferences Data ===');
      print('All keys: ${prefs.getKeys()}');
      prefs.getKeys().forEach((key) {
        print('$key: ${prefs.get(key)}');
      });

      final userString = prefs.getString('user');
      final storeString = prefs.getString('store');

      print('userString: $userString');
      print('storeString: $storeString');

      if (userString != null) {
        final userData = json.decode(userString);
        setState(() {
          userName = userData['name'] ?? 'Nama Kasir';
        });
      }

      if (storeString != null) {
        final storeData = json.decode(storeString);
        print('storeData: $storeData'); // Debug store data
        setState(() {
          storeName = storeData['nickname'] ?? 'SAGANSA';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      // Coba load dari SharedPreferences dulu
      final prefs = await SharedPreferences.getInstance();
      final cachedCategories = prefs.getString('categories');

      if (cachedCategories != null) {
        final List<dynamic> decoded = json.decode(cachedCategories);
        setState(() {
          _categories = [
            CategoryModel(id: 0, name: 'Semua'),
            ...decoded.map((cat) => CategoryModel.fromJson(cat)).toList()
          ];
        });
      }

      // Load dari API
      final categories = await _productService.getCategories();

      // Simpan ke SharedPreferences
      final categoriesJson =
          categories.map((category) => category.toJson()).toList();
      await prefs.setString('categories', json.encode(categoriesJson));

      setState(() {
        _categories = [CategoryModel(id: 0, name: 'Semua'), ...categories];
      });
    } catch (e) {
      print('Error loading categories: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadProducts() async {
    try {
      print('=== Loading Products ===');

      // Load dari API dulu
      final ProductResponse response = await _productService.getProducts();
      print('API Response - cart_count: ${response.cartCount}');

      // Update state dengan data dari API
      setState(() {
        products = response.data.products;
        cartCount = response.cartCount;
      });

      // Update CartProvider dengan cart count dari API
      Provider.of<CartProvider>(context, listen: false)
          .updateCartCount(response.cartCount);

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final productsJson = {
        'status': response.status,
        'cart_count': response.cartCount,
        'data': {
          'products': response.data.products.map((p) => p.toJson()).toList(),
        }
      };

      await prefs.setString('products', json.encode(productsJson));
      print('Products saved to SharedPreferences');
    } catch (e) {
      print('Error loading products: $e');

      // Jika API gagal, coba load dari cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedProducts = prefs.getString('products');

        if (cachedProducts != null) {
          final Map<String, dynamic> decoded = json.decode(cachedProducts);
          final productResponse = ProductResponse.fromJson(decoded);

          setState(() {
            products = productResponse.data.products;
            cartCount = productResponse.cartCount;
          });

          // Update CartProvider dengan cart count dari cache
          Provider.of<CartProvider>(context, listen: false)
              .updateCartCount(productResponse.cartCount);
        }
      } catch (cacheError) {
        print('Error loading from cache: $cacheError');
      }
    }
  }

  // Untuk refresh data setelah kembali dari CartPage
  void _refreshAfterCart() async {
    await _loadProducts();
  }

  List<ProductModel> get filteredProducts {
    var filtered = selectedCategory == 'Semua'
        ? products
        : products
            .where(
                (product) => product.categoryId.toString() == selectedCategory)
            .toList();

    if (searchController.text.isNotEmpty) {
      filtered = filtered
          .where((product) => product.name
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi orientasi dan ukuran layar
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final showSplitView = isLandscape && isTablet;

    final mainContent = Scaffold(
      drawer: showSplitView ? null : _buildDrawer(),
      appBar: AppBar(
        title: Text('Point of Sales'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) => cart.cartCount > 0
                ? Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_cart),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CartPage()),
                          ).then((_) => _refreshAfterCart());
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.cartCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                if (!isSearching)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: _categories.map((CategoryModel category) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                if (isSearching)
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      if (isSearching) {
                        searchController.clear();
                      }
                      isSearching = !isSearching;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isGridView
                ? _buildGridView(filteredProducts)
                : _buildListView(filteredProducts),
          ),
        ],
      ),
    );

    if (!showSplitView) {
      return mainContent;
    }

    // Layout untuk tablet landscape
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 75,
              child: mainContent,
            ),
            Container(
              width: 2,
              color: Colors.grey[300],
            ),
            Expanded(
              flex: 25,
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: CartPage(
                  isEmbedded: true,
                  key: PageStorageKey('embedded_cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  storeName,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Beranda'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Riwayat Transaksi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryPage(),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Keluar',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // Show logout confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Konfirmasi Keluar'),
                  content: Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Implement logout logic here
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close drawer
                        // Navigate to login page or implement logout
                      },
                      child: Text(
                        'Keluar',
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
    );
  }

  Widget _buildGridView(List<ProductModel> items) {
    // Deteksi ukuran layar
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 5 : 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridItem(items[index]);
      },
    );
  }

  Widget _buildListView(List<ProductModel> items) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildListItem(items[index]);
      },
    );
  }

  Widget _buildGridItem(ProductModel product) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToDetail(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                child: product.image != null && product.image!.isNotEmpty
                    ? Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildListItem(ProductModel product) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(8),
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: product.image != null && product.image!.isNotEmpty
                ? Image.network(
                    product.image!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 30,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => _navigateToDetail(product),
      ),
    );
  }

  String formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _navigateToDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product.id),
      ),
    ).then((value) {
      if (value == true) {
        _loadProducts(); // Refresh products setelah kembali dari detail
      }
    });
  }
}
