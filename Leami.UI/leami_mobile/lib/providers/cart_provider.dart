import 'package:flutter/foundation.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

class CartProvider with ChangeNotifier {
  Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};

  int get totalItems {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Deprecated: Use totalPrice instead
  double get total => totalPrice;

  void addItem(dynamic productId, String title, double price) {
    final id = productId;

    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(id, () => CartItem(id: id, name: title, price: price));
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) {
      return;
    }

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (!_items.containsKey(productId)) {
      return;
    }

    if (newQuantity <= 0) {
      _items.remove(productId);
    } else {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: newQuantity,
        ),
      );
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool containsItem(String productId) {
    return _items.containsKey(productId);
  }

  int getItemQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  CartItem? getItem(String productId) {
    return _items[productId];
  }

  List<CartItem> get itemsList => _items.values.toList();
}
