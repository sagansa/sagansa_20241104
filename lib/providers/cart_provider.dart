import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  int _cartCount = 0;

  int get cartCount => _cartCount;

  void updateCartCount(int count) {
    _cartCount = count;
    notifyListeners();
  }

  void incrementCartCount() {
    _cartCount++;
    notifyListeners();
  }

  void setCartCount(int count) {
    _cartCount = count;
    notifyListeners();
  }
}
