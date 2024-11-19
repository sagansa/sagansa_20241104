import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../widgets/modern_button.dart';
import '../models/product_detail_model.dart';
import '../services/product_service.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final bool isEditing;
  final CartItem? cartItem;
  final Function(Map<String, dynamic>)? onUpdateCart;

  const ProductDetailPage({
    Key? key,
    required this.productId,
    this.isEditing = false,
    this.cartItem,
    this.onUpdateCart,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int? selectedVariantId;
  Map<int, int> selectedModifierIds = {};
  int quantity = 1;
  final TextEditingController notesController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  // Tambahkan state untuk menyimpan data produk
  ProductDetailModel? productDetail;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();

    // Inisialisasi data jika dalam mode edit
    if (widget.isEditing && widget.cartItem != null) {
      quantity = widget.cartItem!.quantity;
      quantityController.text = quantity.toString();
      notesController.text = widget.cartItem!.notes ?? '';
    }

    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final productService = ProductService();
      final response = await productService.getProductDetail(widget.productId);

      setState(() {
        productDetail = response.data;

        if (widget.isEditing && widget.cartItem != null) {
          // Set variant yang sudah ada
          final variant = productDetail!.variants.firstWhere(
            (v) => v.name == widget.cartItem!.variantName,
            orElse: () => productDetail!.variants.first,
          );
          selectedVariantId = variant.id;

          // Set modifier berdasarkan data dari cart
          for (var cartModifier in widget.cartItem!.modifiers) {
            // Asumsi format: "Nama Modifier - Nama Detail"
            final parts = cartModifier.split(' - ');
            if (parts.length == 2) {
              final modifierName = parts[0];
              final detailName = parts[1];

              // Cari modifier dan detail yang sesuai
              final modifier = productDetail!.modifiers.firstWhere(
                (m) => m.name == modifierName,
                orElse: () => productDetail!.modifiers.first,
              );

              final detail = modifier.details.firstWhere(
                (d) => d.name == detailName,
                orElse: () => modifier.details.first,
              );

              selectedModifierIds[modifier.id] = detail.id;
            }
          }
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Fungsi helper untuk menghitung total harga
  int _calculateTotalPrice() {
    if (productDetail == null || selectedVariantId == null) return 0;

    final selectedVariant =
        productDetail!.variants.firstWhere((v) => v.id == selectedVariantId);

    final modifiersPrice =
        productDetail!.modifiers.fold<int>(0, (sum, modifier) {
      if (selectedModifierIds.containsKey(modifier.id)) {
        final detailId = selectedModifierIds[modifier.id];
        final detail = modifier.details.firstWhere((d) => d.id == detailId);
        return sum + detail.price;
      }
      return sum;
    });

    return (selectedVariant.price + modifiersPrice) * quantity;
  }

  // Tambahkan fungsi helper untuk memformat harga
  String _formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
      quantityController.text = quantity.toString();
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
        quantityController.text = quantity.toString();
      });
    }
  }

  // Buat konstanta untuk style yang konsisten
  final _buttonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4), // Radius yang konsisten
    ),
  );

  Widget _buildVariantGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: productDetail?.variants.length ?? 0,
      itemBuilder: (context, index) {
        final variant = productDetail!.variants[index];
        final isSelected = selectedVariantId == variant.id;

        return TextButton(
          onPressed: () {
            setState(() {
              selectedVariantId = variant.id;
            });
          },
          style: _buttonStyle.copyWith(
            backgroundColor: MaterialStateProperty.all(
              isSelected ? Colors.black : Colors.grey[200],
            ),
            foregroundColor: MaterialStateProperty.all(
              isSelected ? Colors.white : Colors.black,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${variant.name}\n${_formatPrice(variant.price)}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModifierGrid(Modifier modifier) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: modifier.details.length,
      itemBuilder: (context, index) {
        final detail = modifier.details[index];
        final isSelected = selectedModifierIds[modifier.id] == detail.id;

        return TextButton(
          onPressed: () {
            setState(() {
              if (isSelected) {
                selectedModifierIds.remove(modifier.id);
              } else {
                selectedModifierIds[modifier.id] = detail.id;
              }
            });
          },
          style: _buttonStyle.copyWith(
            backgroundColor: MaterialStateProperty.all(
              isSelected ? Colors.black : Colors.grey[200],
            ),
            foregroundColor: MaterialStateProperty.all(
              isSelected ? Colors.white : Colors.black,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${detail.name}\n${_formatPrice(detail.price)}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  bool _isFormValid() {
    // Cek dasar
    if (selectedVariantId == null || productDetail == null) return false;

    // Cek apakah produk memiliki modifier wajib
    bool hasRequiredModifiers =
        productDetail!.modifiers.any((m) => m.isRequired);

    // Jika ada modifier wajib tapi selectedModifierIds kosong, return false
    if (hasRequiredModifiers && selectedModifierIds.isEmpty) {
      print('Produk memiliki modifier wajib tapi belum dipilih');
      return false;
    }

    // Cek setiap modifier yang required
    for (var modifier in productDetail!.modifiers) {
      if (modifier.isRequired &&
          !selectedModifierIds.containsKey(modifier.id)) {
        print('Modifier ${modifier.name} wajib dipilih');
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: _loadProductDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(productDetail?.name ?? ''),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Variants Section
                    const SizedBox(height: 8),
                    _buildVariantGrid(),

                    // Modifiers Section
                    for (var modifier in productDetail?.modifiers ?? []) ...[
                      const SizedBox(height: 16),
                      Text(
                        modifier.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildModifierGrid(modifier),
                    ],

                    // Quantity Section
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 40,
                          child: TextButton(
                            onPressed: _decrementQuantity,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Icon(Icons.remove),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              controller: quantityController,
                              onChanged: (value) {
                                final newQuantity = int.tryParse(value);
                                if (newQuantity != null && newQuantity > 0) {
                                  setState(() {
                                    quantity = newQuantity;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 40,
                          child: TextButton(
                            onPressed: _incrementQuantity,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),

                    // Notes Section
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatPrice(_calculateTotalPrice()),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernButton(
            text: widget.isEditing ? 'Perbarui' : 'Tambah ke Keranjang',
            onPressed: _isFormValid()
                ? (widget.isEditing ? _updateCartItem : _addToCart)
                : null,
            icon: widget.isEditing ? Icons.save : Icons.shopping_cart,
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    // Validasi awal
    if (productDetail == null || selectedVariantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data produk tidak lengkap')),
      );
      return;
    }

    // Validasi modifier wajib
    bool hasRequiredModifiers =
        productDetail!.modifiers.any((m) => m.isRequired);
    if (hasRequiredModifiers) {
      if (selectedModifierIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih modifier yang wajib')),
        );
        return;
      }

      // Cek setiap modifier yang required
      for (var modifier in productDetail!.modifiers) {
        if (modifier.isRequired &&
            !selectedModifierIds.containsKey(modifier.id)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mohon pilih ${modifier.name}')),
          );
          return;
        }
      }
    }

    try {
      final modifiers = selectedModifierIds.entries
          .map((e) => {
                'modifier_id': e.key,
                'modifier_detail_id': e.value,
              })
          .toList();

      // Jika tidak ada modifier yang dipilih dan ada modifier wajib, hentikan proses
      if (modifiers.isEmpty && hasRequiredModifiers) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih modifier yang wajib')),
        );
        return;
      }

      final cartData = {
        'product_id': productDetail!.id,
        'variant_id': selectedVariantId,
        'modifiers': modifiers,
        'quantity': quantity,
        'notes': notesController.text,
      };

      // Log untuk debugging
      print('Cart data being sent: $cartData');
      final productService = ProductService();
      await productService.addToCart(cartData, context);

      // Update cart counter
      if (!mounted) return;
      context.read<CartProvider>().incrementCartCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil ditambahkan ke keranjang')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
      );
    }
  }

  Future<void> _updateCartItem() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon pilih semua varian dan modifier yang wajib')),
      );
      return;
    }

    if (productDetail == null || selectedVariantId == null) return;

    try {
      final productService = ProductService();

      final payload = {
        'quantity': quantity,
        'notes': notesController.text,
        'variant_id': selectedVariantId,
        'modifiers': selectedModifierIds.entries
            .map((e) => {
                  'modifier_id': e.key,
                  'modifier_detail_id': e.value,
                })
            .toList(),
      };

      await productService.updateCart(widget.cartItem!.id, payload);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil memperbarui item')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
