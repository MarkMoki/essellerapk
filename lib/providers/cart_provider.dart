import 'package:flutter/material.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final Map<String, int> _items = {}; // productId -> quantity

  Map<String, int> get items => _items;

  int get itemCount => _items.values.fold(0, (sum, quantity) => sum + quantity);

  double get totalAmount {
    // This would need product prices, but for now, assume we have a list of products
    // In real app, fetch prices or pass products
    return 0.0; // Placeholder
  }

  void addItem(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId] = _items[productId]! + 1;
    } else {
      _items[productId] = 1;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]! > 1) {
        _items[productId] = _items[productId]! - 1;
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
}