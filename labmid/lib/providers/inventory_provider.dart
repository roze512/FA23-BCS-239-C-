import 'package:flutter/foundation.dart';
import '../models/stock_movement_model.dart';
import '../services/inventory_service.dart';

/// Provider for inventory/stock movement state management
class InventoryProvider with ChangeNotifier {
  final InventoryService _inventoryService = InventoryService();

  List<StockMovementModel> _stockMovements = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _dashboardStats = {};

  List<StockMovementModel> get stockMovements => _stockMovements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get dashboardStats => _dashboardStats;

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

  /// Load all stock movements
  Future<void> loadStockMovements() async {
    try {
      _setLoading(true);
      _setError(null);
      _stockMovements = await _inventoryService.getAllStockMovements();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Load stock movements for a product
  Future<void> loadStockMovementsByProduct(String productId) async {
    try {
      _setLoading(true);
      _setError(null);
      _stockMovements = await _inventoryService.getStockMovementsByProduct(productId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await _inventoryService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Stock in operation
  Future<bool> stockIn({
    required String productId,
    required int quantity,
    String? reason,
    String? supplier,
    String? reference,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _inventoryService.stockIn(
        productId: productId,
        quantity: quantity,
        reason: reason,
        supplier: supplier,
        reference: reference,
        notes: notes,
      );
      if (success) {
        await loadStockMovements(); // Reload stock movements
        await loadDashboardStats(); // Update stats
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Stock out operation
  Future<bool> stockOut({
    required String productId,
    required int quantity,
    String? reason,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _inventoryService.stockOut(
        productId: productId,
        quantity: quantity,
        reason: reason,
        notes: notes,
      );
      if (success) {
        await loadStockMovements(); // Reload stock movements
        await loadDashboardStats(); // Update stats
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
      await _inventoryService.syncFromFirebase(userId);
      await _inventoryService.syncToFirebase();
      await loadStockMovements();
      await loadDashboardStats();
    } catch (e) {
      debugPrint('Error syncing inventory: $e');
    }
  }
}
