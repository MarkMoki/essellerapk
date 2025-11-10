import 'package:flutter/material.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final Map<String, int> _items = {}; // productId -> quantity

  Map<String, int> get items => _items;

  int get itemCount => _items.values.fold(0, (sum, quantity) => sum + quantity);

  double get totalAmount {
    // Calculate total from cart items - this will be computed when getCartItems is called
    return 0.0; // Will be calculated in screens where products are available
  }

  void addItem(String productId, {int quantity = 1}) {
    if (_items.containsKey(productId)) {
      _items[productId] = _items[productId]! + quantity;
    } else {
      _items[productId] = quantity;
    }
    notifyListeners();
  }

  void removeItem(String productId, {int quantity = 1}) {
    if (_items.containsKey(productId)) {
      if (_items[productId]! > quantity) {
        _items[productId] = _items[productId]! - quantity;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getCartItems(List<Product> products) {
    return _items.entries.map((entry) {
      final product = products.firstWhere((p) => p.id == entry.key);
      return {
        'product': product,
        'quantity': entry.value,
      };
    }).toList();
  }

  double getTotalAmount(List<Product> products) {
    return getCartItems(products).fold(0.0, (sum, item) =>
      sum + (item['product'] as Product).price * (item['quantity'] as int));
  }

  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  int getQuantity(String productId) {
    return _items[productId] ?? 0;
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = newQuantity;
    }
    notifyListeners();
  }
}