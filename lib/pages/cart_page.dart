import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../widgets/modern_button.dart';
import 'check_out_page.dart';
import '../services/cart_service.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'product_detail_page.dart';

class CartPage extends StatefulWidget {
  final bool isEmbedded;

  const CartPage({
    super.key,
    this.isEmbedded = false,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];
  final cartService = CartService();
  int? activeDiscount;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      setState(() {
        cartItems = []; // Reset cart items sebelum loading
      });

      final cart = await cartService.getCartItems(context);
      print('Received cart items: ${cart.length}'); // Debug print

      if (mounted) {
        setState(() {
          cartItems = cart;
          print('Cart items set in state: ${cartItems.length}'); // Debug print
        });
      }
    } catch (e) {
      print('Error loading cart: $e');

      if (mounted) {
        String errorMessage = 'Gagal memuat keranjang';

        if (e.toString().contains('Token tidak ditemukan')) {
          errorMessage = 'Sesi telah berakhir. Silakan login kembali';
        } else if (e.toString().contains('HTTP Error')) {
          errorMessage = 'Gagal terhubung ke server';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _loadCart(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateCart() async {
    try {
      for (var item in cartItems) {
        await cartService.updateCart(item.id, {
          'quantity': item.quantity,
          'notes': item.notes,
          'modifiers': item.modifiers,
          'variant_name': item.variantName,
          'variant_price': item.variantPrice,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _updateCartItem(
      int index, Map<String, dynamic> updatedData) async {
    final originalItem = cartItems[index];
    try {
      final payload = {
        'quantity': updatedData['quantity'],
        'notes': originalItem.notes ?? '',
        'variant_name': originalItem.variantName,
        'variant_price': originalItem.variantPrice,
        'modifiers': originalItem.modifiers,
      };

      final response = await cartService.updateCart(originalItem.id, payload);

      setState(() {
        cartItems[index] = CartItem.fromJson({
          ...originalItem.toJson(),
          'quantity': response['quantity'],
          'unit_price': response['unit_price'],
          'subtotal': response['subtotal'],
        });
      });
    } catch (e) {
      print('Error updating cart item: $e');

      // Kembalikan ke state sebelumnya
      setState(() {
        cartItems[index] = originalItem;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal mengubah jumlah. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _updateCartItem(index, updatedData),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeCartItem(int index) async {
    try {
      final item = cartItems[index];

      await cartService.deleteCartItem(item.id);

      setState(() {
        cartItems.removeAt(index);
      });

      Provider.of<CartProvider>(context, listen: false)
          .updateCartCount(cartItems.length);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting cart item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _showDiscountInput(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final TextEditingController tempController = TextEditingController();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tempController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nominal diskon',
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        int parsed =
                            int.tryParse(value.replaceAll('.', '')) ?? 0;
                        String formatted = parsed.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.',
                            );
                        if (formatted != value) {
                          tempController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                                offset: formatted.length),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    scaffoldMessenger.hideCurrentSnackBar();
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    final value = tempController.text.replaceAll('.', '');
                    if (value.isEmpty || int.tryParse(value) == 0) {
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content:
                              Text('Nominal diskon tidak boleh kosong atau 0'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (mounted) {
                      this.setState(() {
                        activeDiscount = int.parse(value);
                      });
                    }
                    scaffoldMessenger.hideCurrentSnackBar();
                  },
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.grey[200],
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _clearCart() async {
    try {
      await cartService.clearCart();

      setState(() {
        cartItems.clear();
      });

      Provider.of<CartProvider>(context, listen: false).updateCartCount(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keranjang berhasil dikosongkan'),
            backgroundColor: Colors.green,
          ),
        );

        // Perbaikan navigasi ke POS page
        if (!widget.isEmbedded) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/pos',
            (route) => false, // Hapus semua route sebelumnya
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengosongkan keranjang'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _incrementQuantity(int index) async {
    try {
      final item = cartItems[index];
      final response = await cartService.incrementQuantity(item.id);

      setState(() {
        cartItems[index] = CartItem.fromJson({
          ...cartItems[index].toJson(),
          'quantity': response['quantity'],
          'subtotal': response['subtotal'],
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _decrementQuantity(int index) async {
    try {
      final item = cartItems[index];
      final response = await cartService.decrementQuantity(item.id);

      setState(() {
        cartItems[index] = CartItem.fromJson({
          ...cartItems[index].toJson(),
          'quantity': response['quantity'],
          'subtotal': response['subtotal'],
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int subtotal = cartItems.fold(0, (sum, item) => sum + item.subtotal);
    int finalTotal = subtotal - (activeDiscount ?? 0);

    return Scaffold(
      appBar: widget.isEmbedded
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AppBar(
                title: const Text('Keranjang'),
                automaticallyImplyLeading: false,
                actions: cartItems.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            // Tampilkan dialog konfirmasi
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Semua'),
                                content: const Text(
                                    'Apakah Anda yakin ingin mengosongkan keranjang?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _clearCart();
                                    },
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          tooltip: 'Hapus Semua',
                        ),
                      ]
                    : null,
              ),
            )
          : AppBar(
              title: const Text('Keranjang'),
              actions: cartItems.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Semua'),
                              content: const Text(
                                  'Apakah Anda yakin ingin mengosongkan keranjang?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearCart();
                                  },
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Hapus Semua',
                      ),
                    ]
                  : null,
            ),
      body: SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Keranjang Kosong',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        return _buildListItem(cartItems[index], index);
                      },
                    ),
            ),
            if (cartItems.isNotEmpty)
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            formatPrice(subtotal),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      if (activeDiscount != null && activeDiscount! > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Diskon:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      activeDiscount = null;
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.red),
                                ),
                              ],
                            ),
                            Text(
                              '- ${formatPrice(activeDiscount!)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (activeDiscount == null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            if (mounted) {
                              _showDiscountInput(context);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Diskon'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatPrice(finalTotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ModernButton(
                        text: 'Proses Pesanan',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckOutPage(
                                finalTotal: finalTotal,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(CartItem item, int index) {
    return SlidableCartItem(
      itemId: item.id.toString(),
      onDelete: () => _removeCartItem(index),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productId: item.productId,
                isEditing: true,
                cartItem: item,
                onUpdateCart: (updatedData) =>
                    _updateCartItem(index, updatedData),
              ),
            ),
          ).then((_) => _loadCart());
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      formatPrice(item.subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (item.variantName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Variant: ${item.variantName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        formatPrice(item.variantPrice),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.modifiers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...item.modifiers.map((modifier) {
                    final parts = modifier.split(' - ');
                    if (parts.length >= 2) {
                      final nameParts = parts[0].trim();
                      final detailParts = parts[1].split('(');
                      if (detailParts.length >= 2) {
                        final detail = detailParts[0].trim();
                        final price = detailParts[1].replaceAll(')', '').trim();

                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$nameParts - $detail',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Rp $price',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    return Text(
                      modifier,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    );
                  }),
                ],
                if (item.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Catatan: ${item.notes}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: item.quantity > 1
                              ? () => _decrementQuantity(index)
                              : null,
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _incrementQuantity(index),
                        ),
                      ],
                    ),
                    Text(
                      '@${formatPrice(item.unitPrice)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SlidableCartItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String itemId;

  const SlidableCartItem({
    super.key,
    required this.child,
    required this.onDelete,
    required this.itemId,
  });

  @override
  State<SlidableCartItem> createState() => _SlidableCartItemState();
}

class _SlidableCartItemState extends State<SlidableCartItem> {
  double _dragExtent = 0;
  bool _deleteButtonVisible = false;

  @override
  void didUpdateWidget(SlidableCartItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _dragExtent = 0;
      _deleteButtonVisible = false;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    final maxDrag = MediaQuery.of(context).size.width * 0.15;
    final newDragExtent = (_dragExtent - details.delta.dx).clamp(0.0, maxDrag);

    if (newDragExtent != _dragExtent) {
      setState(() {
        _dragExtent = newDragExtent;
        _deleteButtonVisible = _dragExtent >= maxDrag;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!mounted) return;
    final maxDrag = MediaQuery.of(context).size.width * 0.15;

    setState(() {
      if (_dragExtent < maxDrag / 2) {
        _dragExtent = 0;
        _deleteButtonVisible = false;
      } else {
        _dragExtent = maxDrag;
        _deleteButtonVisible = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(-_dragExtent, 0),
            child: widget.child,
          ),
          if (_deleteButtonVisible)
            Positioned(
              top: 8,
              bottom: 8,
              right: 0,
              width: MediaQuery.of(context).size.width * 0.15,
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    widget.onDelete();
                  }
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
