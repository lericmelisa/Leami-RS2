import 'package:flutter/material.dart';

class CartItem {
  final int articleId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.articleId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  double get total =>
      _items.values.fold(0, (sum, item) => sum + item.price * item.quantity);

  void addItem(int id, String name, double price) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(articleId: id, name: name, price: price);
    }
    notifyListeners();
  }

  void removeItem(int id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
