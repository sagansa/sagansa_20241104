import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../widgets/modern_button.dart';
import 'check_out_page.dart';
import '../services/cart_service.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartPage extends StatefulWidget {
  final bool isEmbedded;

  const CartPage({
    Key? key,
    this.isEmbedded = false,
  }) : super(key: key);

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

      final cart = await cartService.getCartItems();

      if (mounted) {
        setState(() {
          cartItems = cart.items;
          print('Cart loaded successfully. Items count: ${cart.items.length}');
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
            duration: Duration(seconds: 3),
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
      int index, Map<String, dynamic> updatedItem) async {
    final originalItem = cartItems[index];
    try {
      final newQuantity = updatedItem['quantity'];

      // Update state lokal
      setState(() {
        cartItems[index] = CartItem.fromJson({
          ...cartItems[index].toJson(),
          ...updatedItem,
          'subtotal': newQuantity * cartItems[index].unitPrice,
        });
      });

      // Perbaiki format data untuk API
      final payload = {
        'quantity': newQuantity,
        'notes': originalItem.notes ?? '',
        'modifiers': originalItem.modifiers
            .map((m) => {
                  'name': m.split(' - ')[0].trim(),
                  'option': m.split(' - ')[1].split('(')[0].trim(),
                  'price': int.parse(m
                      .split('(')[1]
                      .replaceAll(')', '')
                      .replaceAll(',', '')
                      .trim())
                })
            .toList(),
        'variant_name': originalItem.variantName ?? '',
        'variant_price': originalItem.variantPrice ?? 0,
      };

      await cartService.updateCart(originalItem.id, payload);
    } catch (e) {
      print('Detailed error: $e');
      if (mounted) {
        setState(() {
          cartItems[index] = originalItem;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah jumlah. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () => _updateCartItem(index, updatedItem),
            ),
          ),
        );
      }
      print('Error updating cart: $e');
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
        duration: Duration(days: 1),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    scaffoldMessenger.hideCurrentSnackBar();
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    final value = tempController.text.replaceAll('.', '');
                    if (value.isEmpty || int.tryParse(value) == 0) {
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
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
                  child: Text(
                    'Terapkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.grey[200],
        padding: EdgeInsets.all(16),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengosongkan keranjang'),
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
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: AppBar(
                title: Text('Keranjang'),
                automaticallyImplyLeading: false,
              ),
            )
          : AppBar(
              title: Text('Keranjang'),
            ),
      body: Container(
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
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
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
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
                          Text(
                            'Subtotal:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            formatPrice(subtotal),
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      if (activeDiscount != null && activeDiscount! > 0) ...[
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Diskon:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      activeDiscount = null;
                                    });
                                  },
                                  child: Icon(Icons.close,
                                      size: 16, color: Colors.red),
                                ),
                              ],
                            ),
                            Text(
                              '- ${formatPrice(activeDiscount!)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (activeDiscount == null) ...[
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            if (mounted) {
                              _showDiscountInput(context);
                            }
                          },
                          icon: Icon(Icons.add),
                          label: Text('Tambah Diskon'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                      Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatPrice(finalTotal),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
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
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    formatPrice(item.subtotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (item.variantName != null) ...[
                SizedBox(height: 4),
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
                SizedBox(height: 4),
                ...item.modifiers.map((modifier) {
                  final parts = modifier.split(' - ');
                  if (parts.length >= 2) {
                    final nameParts = parts[0].trim();
                    final detailParts = parts[1].split('(');
                    if (detailParts.length >= 2) {
                      final detail = detailParts[0].trim();
                      final price = detailParts[1].replaceAll(')', '').trim();

                      return Padding(
                        padding: EdgeInsets.only(top: 2),
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
                SizedBox(height: 4),
                Text(
                  'Catatan: ${item.notes}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: item.quantity > 1
                            ? () => _updateCartItem(
                                  index,
                                  {'quantity': item.quantity - 1},
                                )
                            : null,
                      ),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _updateCartItem(
                          index,
                          {'quantity': item.quantity + 1},
                        ),
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
    );
  }
}

class SlidableCartItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String itemId;

  const SlidableCartItem({
    Key? key,
    required this.child,
    required this.onDelete,
    required this.itemId,
  }) : super(key: key);

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
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
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
