import 'package:flutter/foundation.dart';
import '../models/sale_model.dart';
import '../models/cart_item_model.dart';
import '../services/sales_service.dart';

/// Provider for managing sales transactions
class SalesProvider with ChangeNotifier {
  final SalesService _salesService = SalesService();
  
  List<SaleModel> _sales = [];
  SaleModel? _currentSale;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SaleModel> get sales => _sales;
  SaleModel? get currentSale => _currentSale;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all sales
  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _salesService.getSales();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load today's sales
  Future<void> loadTodaysSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _salesService.getTodaysSales();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get today's sales total
  Future<double> getTodaysSalesTotal() async {
    try {
      return await _salesService.getTodaysSalesTotal();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0.0;
    }
  }

  /// Load sales by customer
  Future<void> loadSalesByCustomer(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _salesService.getSalesByCustomer(customerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new sale
  Future<String?> createSale({
    required String customerId,
    required String customerName,
    required List<CartItemModel> items,
    required double subtotal,
    required double discount,
    String? discountType,
    required double tax,
    required double taxRate,
    required double total,
    required String paymentMethod,
    required String paymentStatus,
    required String cashierId,
    required String cashierName,
  }) async {
    try {
      final sale = SaleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customerId == 'walk-in' ? null : customerId,
        customerName: customerName,
        items: items,
        subtotal: subtotal,
        discount: discount,
        discountType: discountType,
        tax: tax,
        taxRate: taxRate,
        total: total,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        cashierId: cashierId,
        cashierName: cashierName,
      );

      final saleId = await _salesService.createSale(sale);
      _currentSale = sale;
      await loadSales();
      notifyListeners();
      return saleId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get sale by ID
  Future<SaleModel?> getSaleById(String id) async {
    try {
      return await _salesService.getSaleById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear current sale
  void clearCurrentSale() {
    _currentSale = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Calculate totals with tax and discount
  Map<String, double> calculateTotals({
    required double subtotal,
    double discount = 0.0,
    String? discountType,
    double taxRate = 8.0,
  }) {
    return _salesService.calculateTotals(
      subtotal: subtotal,
      discount: discount,
      discountType: discountType,
      taxRate: taxRate,
    );
  }
}
