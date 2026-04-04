import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';

/// Provider for managing customers
class CustomerProvider with ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  
  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;
  String _filterType = 'all'; // all, active, debtors, credit, inactive
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CustomerModel> get customers => _customers;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  String get filterType => _filterType;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get filtered customers based on current filter
  List<CustomerModel> get filteredCustomers {
    List<CustomerModel> filtered = _customers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        final nameLower = customer.name.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        final phoneLower = customer.phone?.toLowerCase() ?? '';
        return nameLower.contains(queryLower) || phoneLower.contains(queryLower);
      }).toList();
    }

    // Apply type filter
    switch (_filterType) {
      case 'active':
        filtered = filtered.where((c) => c.isActive).toList();
        break;
      case 'debtors':
        filtered = filtered.where((c) => c.isDebtor).toList();
        break;
      case 'credit':
        filtered = filtered.where((c) => c.hasCredit).toList();
        break;
      case 'inactive':
        filtered = filtered.where((c) => !c.isActive).toList();
        break;
      default:
        // 'all' - no filter
        break;
    }

    return filtered;
  }

  /// Load all customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _customerService.getCustomers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load customers by filter type
  Future<void> loadCustomersByFilter(String filter) async {
    _isLoading = true;
    _error = null;
    _filterType = filter;
    notifyListeners();

    try {
      switch (filter) {
        case 'active':
          _customers = await _customerService.getActiveCustomers();
          break;
        case 'debtors':
          _customers = await _customerService.getDebtors();
          break;
        case 'credit':
          _customers = await _customerService.getCreditCustomers();
          break;
        case 'inactive':
          _customers = await _customerService.getInactiveCustomers();
          break;
        default:
          _customers = await _customerService.getCustomers();
          break;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set filter type
  void setFilter(String filter) {
    _filterType = filter;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Select customer for transaction
  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  /// Add new customer
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _customerService.addCustomer(customer);
      await loadCustomers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update customer
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _customerService.updateCustomer(customer);
      await loadCustomers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    try {
      await _customerService.deleteCustomer(id);
      await loadCustomers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get customer by ID
  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      return await _customerService.getCustomerById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear selected customer
  void clearSelection() {
    _selectedCustomer = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
