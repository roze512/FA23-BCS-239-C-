import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

/// Provider for category state management
class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  CategoryModel? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get total categories count
  int get totalCategoriesCount => _categories.length;

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

  /// Load all categories
  Future<void> loadCategories() async {
    try {
      _setLoading(true);
      _setError(null);
      _categories = await _categoryService.getAllCategories();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Get categories with product counts
  Future<List<Map<String, dynamic>>> getCategoriesWithCounts() async {
    try {
      return await _categoryService.getAllCategoriesWithCounts();
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Select a category
  void selectCategory(CategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Get category by ID
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      return await _categoryService.getCategoryById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Create new category
  Future<bool> createCategory(CategoryModel category) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _categoryService.createCategory(category);
      if (success) {
        await loadCategories(); // Reload categories list
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Add new category (alias for createCategory)
  Future<bool> addCategory(CategoryModel category) async {
    return await createCategory(category);
  }

  /// Update category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _categoryService.updateCategory(category);
      if (success) {
        await loadCategories(); // Reload categories list
        if (_selectedCategory?.id == category.id) {
          _selectedCategory = category;
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

  /// Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      _setLoading(true);
      _setError(null);
      final success = await _categoryService.deleteCategory(id);
      if (success) {
        await loadCategories(); // Reload categories list
        if (_selectedCategory?.id == id) {
          _selectedCategory = null;
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
      await _categoryService.syncFromFirebase(userId);
      await _categoryService.syncToFirebase();
      await loadCategories();
    } catch (e) {
      debugPrint('Error syncing categories: $e');
    }
  }
}
