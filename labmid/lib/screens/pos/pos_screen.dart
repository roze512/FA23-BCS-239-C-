import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../utils/format_helper.dart';
import 'select_customer_screen.dart';

/// POS Main Screen with product grid and cart panel
class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  final DraggableScrollableController _cartController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    await Future.wait([
      productProvider.loadProducts(),
      categoryProvider.loadCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Main content (product grid) - takes full screen
          Positioned.fill(
            child: Column(
              children: [
                // App bar
                _buildAppBar(),
                // Search bar
                _buildSearchBar(),
                // Category filter
                _buildCategoryFilter(),
                // Product grid (scrollable)
                Expanded(
                  child: _buildProductGrid(),
                ),
                // Space for collapsed cart + bottom nav clearance
                const SizedBox(height: 160),
              ],
            ),
          ),
          
          // Draggable cart panel - on top of everything
          _buildCartPanel(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.only(top: 40, left: 8, right: 8, bottom: 8),
      child: Row(
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cashier',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        authProvider.user?.name ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search products by name or SKU...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final categories = categoryProvider.categories;
        
        return SizedBox(
          height: 50,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip('All Items', 'all'),
              ...categories.map((category) => 
                _buildCategoryChip(category.name, category.id)
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, String categoryId) {
    final isSelected = _selectedCategory == categoryId;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = categoryId;
          });
        },
        backgroundColor: AppTheme.surfaceDark,
        selectedColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        var products = productProvider.products;
        
        // Filter by search query
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          products = products.where((product) {
            return product.name.toLowerCase().contains(query) ||
                   (product.sku?.toLowerCase().contains(query) ?? false);
          }).toList();
        }
        
        // Filter by category
        if (_selectedCategory != 'all') {
          products = products.where((product) => product.categoryId == _selectedCategory).toList();
        }
        
        if (products.isEmpty) {
          return Center(
            child: Text(
              'No products found',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildProductCard(products[index]),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isOutOfStock = product.quantity == 0;
    final isLowStock = product.isLowStock && !isOutOfStock;
    
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: isOutOfStock ? AppTheme.surfaceDark.withOpacity(0.5) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: (product.imageUrl?.isNotEmpty == true)
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.primaryGreen,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.inventory_2,
                                size: 48,
                                color: isOutOfStock 
                                    ? AppTheme.textSecondary.withOpacity(0.3)
                                    : AppTheme.primaryGreen.withOpacity(0.5),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.inventory_2,
                              size: 48,
                              color: isOutOfStock 
                                  ? AppTheme.textSecondary.withOpacity(0.3)
                                  : AppTheme.primaryGreen.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),
              ),
              
              // Product info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOutOfStock 
                            ? AppTheme.textSecondary.withOpacity(0.2)
                            : isLowStock
                                ? AppTheme.alertRed.withOpacity(0.2)
                                : AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOutOfStock 
                            ? 'OUT OF STOCK'
                            : isLowStock
                                ? 'LOW STOCK'
                                : '${product.quantity} LEFT',
                        style: TextStyle(
                          color: isOutOfStock 
                              ? AppTheme.textSecondary
                              : isLowStock
                                  ? AppTheme.alertRed
                                  : AppTheme.primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Product name
                    Text(
                      product.name,
                      style: TextStyle(
                        color: isOutOfStock ? AppTheme.textSecondary : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          FormatHelper.formatPrice(product.price, symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol),
                          style: TextStyle(
                            color: isOutOfStock ? AppTheme.textSecondary : AppTheme.primaryGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                          onPressed: isOutOfStock
                              ? null
                              : () {
                                  cartProvider.addItem(product);
                                },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartPanel() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final bool isEmpty = cartProvider.isEmpty;
        // Get the bottom nav bar height to ensure cart doesn't overlap it
        final bottomNavHeight = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
        final screenHeight = MediaQuery.of(context).size.height;
        // Calculate fractional offset for bottom nav clearance
        final bottomNavFraction = bottomNavHeight / screenHeight;
        
        // Sizes that account for the bottom navigation bar
        final double emptyInitial = 0.10 + bottomNavFraction;
        final double emptyMin = 0.08 + bottomNavFraction;
        final double hasItemsInitial = 0.18 + bottomNavFraction;
        final double hasItemsMin = 0.18 + bottomNavFraction;
        
        return DraggableScrollableSheet(
          controller: _cartController,
          initialChildSize: isEmpty ? emptyInitial : hasItemsInitial,
          minChildSize: isEmpty ? emptyMin : hasItemsMin,
          maxChildSize: isEmpty ? emptyInitial : 0.90,
          snap: true,
          snapSizes: isEmpty ? [emptyInitial] : [hasItemsInitial, 0.55, 0.90],
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {
                // Toggle cart expansion on tap of header area
                if (!isEmpty && _cartController.size < 0.5) {
                  _cartController.animateTo(
                    0.90,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    
                    // Cart header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Cart (${cartProvider.itemCount} items)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (cartProvider.itemCount > 0)
                            TextButton(
                              onPressed: () {
                                cartProvider.clearCart();
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: AppTheme.alertRed),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Cart content
                    Expanded(
                      child: isEmpty
                          // Empty state: compact, no large icon/text overlay
                          ? const SizedBox.shrink()
                          : ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                const SizedBox(height: 8),
                                ...cartProvider.items.map((item) => _buildCartItem(item, cartProvider)),
                                const SizedBox(height: 16),
                                
                                // Add Discount Button
                                InkWell(
                                  onTap: () => _showDiscountDialog(cartProvider),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.local_offer, color: AppTheme.primaryGreen, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          cartProvider.discount > 0 
                                            ? 'Discount: ${cartProvider.discountAmount.toStringAsFixed(2)}'
                                            : 'Add Discount',
                                          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                _buildCartSummary(cartProvider),
                                const SizedBox(height: 100),
                              ],
                            ),
                    ),
                    
                    // Proceed button - visible when cart has items
                    if (cartProvider.itemCount > 0)
                      Container(
                        padding: EdgeInsets.only(
                          left: 16, 
                          right: 16, 
                          top: 12, 
                          // Add enough bottom padding to clear the bottom nav bar
                          bottom: bottomNavHeight + 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          border: Border(
                            top: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SelectCustomerScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed to Payment',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                    
                    // Bottom spacer for empty cart to clear nav bar
                    if (isEmpty)
                      SizedBox(height: bottomNavHeight + 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(dynamic item, CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: AppTheme.primaryGreen.withOpacity(0.5),
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name and delete button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.alertRed, size: 18),
                      onPressed: () {
                        cartProvider.removeItem(item.productId);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Price, quantity and total row
                Row(
                  children: [
                    // Price (editable) - compact
                    GestureDetector(
                      onTap: () {
                        _showEditPriceDialog(item, cartProvider);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, size: 10, color: AppTheme.primaryGreen),
                            const SizedBox(width: 3),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quantity controls
                    GestureDetector(
                      onTap: () {
                        cartProvider.decrementQuantity(item.productId);
                      },
                      child: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryGreen, size: 22),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        cartProvider.incrementQuantity(item.productId);
                      },
                      child: const Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 22),
                    ),
                    const Spacer(),
                    // Line total - won't shrink/clip
                    Text(
                      FormatHelper.formatPrice(item.lineTotal, symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              Text(
                FormatHelper.formatPrice(cartProvider.subtotal, symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Discount (Money only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  _showDiscountDialog(cartProvider);
                },
                icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryGreen),
                label: const Text(
                  'Add Discount',
                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 14),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
              if (cartProvider.discount > 0)
                Text(
                  '-${FormatHelper.formatPrice(cartProvider.discountAmount, symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol)}',
                  style: const TextStyle(color: AppTheme.alertRed, fontSize: 14),
                ),
            ],
          ),
          const Divider(color: AppTheme.borderDark, height: 24),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                FormatHelper.formatPrice(cartProvider.total, symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol),
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(dynamic item, CartProvider cartProvider) {
    final TextEditingController priceController = TextEditingController(
      text: item.customPrice.toStringAsFixed(2),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Edit Price', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(color: AppTheme.primaryGreen),
            hintText: 'Enter new price',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                cartProvider.updateCustomPrice(item.productId, newPrice);
                Navigator.pop(context);
              }
            },
            child: const Text('Update', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(CartProvider cartProvider) {
    final TextEditingController discountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Add Discount (Rs)', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixText: 'Rs ',
                prefixStyle: TextStyle(color: AppTheme.primaryGreen),
                hintText: 'Enter discount amount',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          if (cartProvider.discount > 0)
            TextButton(
              onPressed: () {
                cartProvider.removeDiscount();
                Navigator.pop(context);
              },
              child: const Text('Remove', style: TextStyle(color: AppTheme.alertRed)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final discount = double.tryParse(discountController.text);
              if (discount != null && discount > 0) {
                cartProvider.setDiscount(discount);
                Navigator.pop(context);
              }
            },
            child: const Text('Apply', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
