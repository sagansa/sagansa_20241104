import 'package:flutter/material.dart';
import '../widgets/modern_button.dart';
import '../models/product_detail_model.dart';
import '../services/product_service.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  const ProductDetailPage({
    super.key,
    required this.productId,
  });

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
    quantityController.text = quantity.toString();
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
            Container(
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
                  // Total section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatPrice(_calculateTotalPrice()),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Button section
                  ModernButton(
                    text: 'Tambah ke Keranjang',
                    onPressed: selectedVariantId == null ? null : _addToCart,
                    icon: Icons.shopping_cart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (productDetail == null || selectedVariantId == null) return;

    try {
      // Format modifier sesuai dengan API
      final modifiers = selectedModifierIds.entries
          .map((e) => {
                'modifier_id': e.key,
                'modifier_detail_id': e.value,
              })
          .toList();

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
      await productService.addToCart(cartData);

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
}
