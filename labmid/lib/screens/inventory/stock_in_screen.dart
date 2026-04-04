import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';

/// Stock In screen
class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _supplierController = TextEditingController();
  final _referenceController = TextEditingController();
  
  ProductModel? _selectedProduct;
  String? _selectedReason = 'Purchase Order';
  int _quantity = 1;

  final List<String> _reasons = [
    'Purchase Order',
    'Customer Return',
    'Inventory Transfer',
    'Gift/Promo',
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _stockIn() async {
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

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final success = await provider.stockIn(
      productId: _selectedProduct!.id,
      quantity: int.parse(_quantityController.text),
      reason: _selectedReason,
      supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
      reference: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
    );

    if (success && mounted) {
      // Reload products
      await Provider.of<ProductProvider>(context, listen: false).loadProducts();
      
      Fluttertoast.showToast(
        msg: 'Stock added successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context);
    } else if (mounted) {
      Fluttertoast.showToast(
        msg: 'Failed to add stock',
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
        title: const Text('Stock In'),
        backgroundColor: AppTheme.surfaceDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Fluttertoast.showToast(
                msg: 'Barcode scanner coming soon',
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
            _buildDetailsSection(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _selectedProduct == null ? null : _stockIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm Stock In'),
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
                  'Current Stock: ${_selectedProduct!.quantity}',
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
            const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 20),
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
                    icon: const Icon(Icons.remove_circle, color: AppTheme.primaryGreen, size: 32),
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
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final current = int.parse(_quantityController.text);
                      _quantityController.text = (current + 1).toString();
                    },
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 32),
                  ),
                ],
              ),
              if (_selectedProduct != null)
                Text(
                  'Stock: ${_selectedProduct!.quantity} → ${_selectedProduct!.quantity + (int.tryParse(_quantityController.text) ?? 0)}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedReason,
          decoration: const InputDecoration(
            labelText: 'Reason',
          ),
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: Colors.white),
          items: _reasons.map((reason) {
            return DropdownMenuItem(
              value: reason,
              child: Text(reason),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _supplierController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Supplier (Optional)',
            hintText: 'Enter supplier name',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _referenceController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Reference/Invoice # (Optional)',
            hintText: 'Enter reference number',
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
                    onTap: () {
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
