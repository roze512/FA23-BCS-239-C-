import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/category_model.dart';

/// Categories Screen - List and manage product categories
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    await Future.wait([
      categoryProvider.loadCategories(),
      productProvider.loadProducts(),
    ]);
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final productsInCategory = productProvider.products.where((p) => p.categoryId == category.id).length;

    if (productsInCategory > 0) {
      Fluttertoast.showToast(
        msg: 'Cannot delete category with $productsInCategory products',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Category', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.alertRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        await categoryProvider.deleteCategory(category.id);
        Fluttertoast.showToast(
          msg: 'Category deleted successfully',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Failed to delete category: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Categories', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Consumer2<CategoryProvider, ProductProvider>(
        builder: (context, categoryProvider, productProvider, child) {
          final categories = categoryProvider.categories;

          if (categoryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
              ),
            );
          }

          if (categories.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryGreen,
            backgroundColor: AppTheme.surfaceDark,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final productCount = productProvider.products.where((p) => p.categoryId == category.id).length;
                return _buildCategoryCard(category, productCount);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addCategory),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: AppTheme.backgroundDark),
        label: const Text(
          'Add Category',
          style: TextStyle(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int productCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildCategoryImage(category.imageUrl),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null) ...[
              const SizedBox(height: 4),
              Text(
                category.description!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$productCount Products',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppTheme.surfaceDark,
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
              onTap: () {
                // TODO: Implement edit category
                Future.delayed(Duration.zero, () {
                  Fluttertoast.showToast(msg: 'Edit category coming soon');
                });
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.alertRed, size: 20),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppTheme.alertRed)),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _deleteCategory(category);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Check if it's a local file path or network URL
      if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
        return Image.file(
          File(imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        );
      } else {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        );
      }
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.primaryGreen.withOpacity(0.1),
      child: const Icon(
        Icons.category,
        color: AppTheme.primaryGreen,
        size: 32,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No categories yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create categories to organize your products',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addCategory),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.backgroundDark,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
