import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

/// Provider for managing shopping cart state
class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];
  double _discount = 0.0;
  // Tax removed as per requirements

  // Getters
  List<CartItemModel> get items => _items;
  int get itemCount => _items.length;
  double get discount => _discount;

  /// Calculate subtotal (sum of all line totals)
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  /// Calculate discount amount (always fixed money amount)
  double get discountAmount {
    return _discount;
  }

  /// Calculate total (subtotal - discount, no tax)
  double get total {
    return subtotal - discountAmount;
  }

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  /// Get item by product ID
  CartItemModel? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Add item to cart
  void addItem(ProductModel product) {
    final existingItem = getItem(product.id);
    
    if (existingItem != null) {
      // Increment quantity if item already in cart
      updateQuantity(product.id, existingItem.quantity + 1);
    } else {
      // Add new item to cart
      _items.add(CartItemModel(
        productId: product.id,
        productName: product.name,
        productImage: product.imageUrl,
        unitPrice: product.price,
        customPrice: product.price,
        quantity: 1,
      ));
      notifyListeners();
    }
  }

  /// Remove item from cart
  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  /// Increment item quantity
  void incrementQuantity(String productId) {
    final item = getItem(productId);
    if (item != null) {
      updateQuantity(productId, item.quantity + 1);
    }
  }

  /// Decrement item quantity
  void decrementQuantity(String productId) {
    final item = getItem(productId);
    if (item != null && item.quantity > 1) {
      updateQuantity(productId, item.quantity - 1);
    } else if (item != null && item.quantity == 1) {
      removeItem(productId);
    }
  }

  /// Update item custom price
  void updateCustomPrice(String productId, double price) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(customPrice: price);
      notifyListeners();
    }
  }

  /// Set discount (fixed money amount only)
  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  /// Remove discount
  void removeDiscount() {
    _discount = 0.0;
    notifyListeners();
  }

  /// Clear cart
  void clearCart() {
    _items.clear();
    _discount = 0.0;
    notifyListeners();
  }

  /// Get cart summary
  Map<String, dynamic> getSummary() {
    return {
      'itemCount': itemCount,
      'subtotal': subtotal,
      'discount': discountAmount,
      'total': total,
    };
  }
}
