import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

/// Provider for product state management
class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  String? _selectedCategoryId;
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get filtered products based on category
  List<ProductModel> get filteredProducts {
    if (_selectedCategoryId == null || _selectedCategoryId == 'all') {
      return _products;
    }
    return _products.where((p) => p.categoryId == _selectedCategoryId).toList();
  }

  /// Get low stock products
  List<ProductModel> get lowStockProducts {
    return _products.where((p) => p.isLowStock).toList();
  }

  /// Get total products count
  int get totalProductsCount => _products.length;

  /// Get total stock value
  double get totalStockValue {
    return _products.fold(0.0, (sum, product) => sum + (product.price * product.quantity));
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Load all products
  Future<void> loadProducts() async {
    try {
      _setLoading(true);
      _setError(null);
      _products = await _productService.getAllProducts();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    try {
      _setLoading(true);
      _setError(null);
      if (query.isEmpty) {
        _products = await _productService.getAllProducts();
      } else {
        _products = await _productService.searchProducts(query);
      }
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Set selected category filter
  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Select a product
  void selectProduct(ProductModel? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      return await _productService.getProductById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Create new product
  Future<bool> createProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _productService.createProduct(product);
      if (success) {
        await loadProducts(); // Reload products list
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update product
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _productService.updateProduct(product);
      if (success) {
        await loadProducts(); // Reload products list
        if (_selectedProduct?.id == product.id) {
          _selectedProduct = product;
        }
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String id) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _productService.deleteProduct(id);
      if (success) {
        await loadProducts(); // Reload products list
        if (_selectedProduct?.id == id) {
          _selectedProduct = null;
        }
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sync with Firebase
  Future<void> syncWithFirebase(String userId) async {
    try {
      await _productService.syncFromFirebase(userId);
      await _productService.syncToFirebase();
      await loadProducts();
    } catch (e) {
      debugPrint('Error syncing products: $e');
    }
  }
}
