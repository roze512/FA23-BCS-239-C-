import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';

/// Stock Out screen
class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  
  ProductModel? _selectedProduct;
  String? _selectedReason = 'Damaged';

  final List<Map<String, dynamic>> _reasons = [
    {'value': 'Damaged', 'icon': Icons.broken_image, 'color': Colors.red},
    {'value': 'Expired', 'icon': Icons.calendar_today, 'color': Colors.orange},
    {'value': 'Sold', 'icon': Icons.shopping_cart, 'color': Colors.blue},
    {'value': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _stockOut() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      Fluttertoast.showToast(
        msg: 'Please select a product',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity > _selectedProduct!.quantity) {
      Fluttertoast.showToast(
        msg: 'Quantity exceeds available stock',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final success = await provider.stockOut(
      productId: _selectedProduct!.id,
      quantity: quantity,
      reason: _selectedReason,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success && mounted) {
      // Reload products
      await Provider.of<ProductProvider>(context, listen: false).loadProducts();
      
      Fluttertoast.showToast(
        msg: 'Stock removed successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context);
    } else if (mounted) {
      Fluttertoast.showToast(
        msg: 'Failed to remove stock',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Stock Out'),
        backgroundColor: AppTheme.surfaceDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Fluttertoast.showToast(
                msg: 'History coming soon',
                backgroundColor: Colors.blue,
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProductSelection(),
            const SizedBox(height: 24),
            if (_selectedProduct != null) _buildSelectedProduct(),
            if (_selectedProduct != null) const SizedBox(height: 24),
            _buildQuantitySection(),
            const SizedBox(height: 24),
            _buildReasonSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _selectedProduct == null ? null : _stockOut,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.alertRed,
              ),
              child: const Text('Confirm Stock Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Product Selection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            return InkWell(
              onTap: () => _showProductPicker(productProvider.products),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedProduct == null
                            ? 'Search and select product...'
                            : 'Change product',
                        style: TextStyle(
                          color: _selectedProduct == null
                              ? AppTheme.textSecondary
                              : AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedProduct() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: AppTheme.primaryGreen.withOpacity(0.5),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedProduct!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_selectedProduct!.sku != null)
                  Text(
                    'SKU: ${_selectedProduct!.sku}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Available Stock: ${_selectedProduct!.quantity}',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedProduct = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.remove_circle_outline, color: AppTheme.alertRed, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Quantity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      final current = int.parse(_quantityController.text);
                      if (current > 1) {
                        _quantityController.text = (current - 1).toString();
                      }
                    },
                    icon: const Icon(Icons.remove_circle, color: AppTheme.alertRed, size: 32),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 1) {
                          return 'Invalid';
                        }
                        if (_selectedProduct != null && qty > _selectedProduct!.quantity) {
                          return 'Exceeds stock';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final current = int.parse(_quantityController.text);
                      if (_selectedProduct == null || current < _selectedProduct!.quantity) {
                        _quantityController.text = (current + 1).toString();
                      }
                    },
                    icon: const Icon(Icons.add_circle, color: AppTheme.alertRed, size: 32),
                  ),
                ],
              ),
              if (_selectedProduct != null)
                Column(
                  children: [
                    Text(
                      'Stock: ${_selectedProduct!.quantity} → ${_selectedProduct!.quantity - (int.tryParse(_quantityController.text) ?? 0)}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if ((int.tryParse(_quantityController.text) ?? 0) > _selectedProduct!.quantity)
                      const Text(
                        '⚠️ Quantity exceeds available stock',
                        style: TextStyle(
                          color: AppTheme.alertRed,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Reason',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _reasons.map((reason) {
            final isSelected = _selectedReason == reason['value'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedReason = reason['value'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? reason['color'].withOpacity(0.2) : AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? reason['color'] : AppTheme.borderDark,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      reason['icon'],
                      color: isSelected ? reason['color'] : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reason['value'],
                      style: TextStyle(
                        color: isSelected ? reason['color'] : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.note_outlined, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add additional notes...',
          ),
        ),
      ],
    );
  }

  void _showProductPicker(List<ProductModel> products) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Select Product',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Stock: ${product.quantity} | \$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: product.quantity == 0
                        ? const Text(
                            'Out of Stock',
                            style: TextStyle(color: AppTheme.alertRed, fontSize: 12),
                          )
                        : null,
                    onTap: product.quantity == 0
                        ? null
                        : () {
                            setState(() {
                              _selectedProduct = product;
                            });
                            Navigator.pop(context);
                          },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
