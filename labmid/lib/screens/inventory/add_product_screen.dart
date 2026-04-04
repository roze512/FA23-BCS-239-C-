import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/product_model.dart';
import '../../utils/validators.dart';

/// Add Product screen
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '10');
  final _imageUrlController = TextEditingController();
  
  String? _selectedCategoryId;
  String _selectedUnitType = 'item';
  double? _projectedMargin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    _priceController.addListener(_calculateMargin);
    _costPriceController.addListener(_calculateMargin);
    _imageUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _calculateMargin() {
    final price = double.tryParse(_priceController.text);
    final costPrice = double.tryParse(_costPriceController.text);
    if (price != null && costPrice != null && price > 0) {
      setState(() {
        _projectedMargin = ((price - costPrice) / price * 100);
      });
    } else {
      setState(() {
        _projectedMargin = null;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final product = ProductModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: _costPriceController.text.isEmpty ? null : double.tryParse(_costPriceController.text),
        quantity: int.parse(_quantityController.text),
        minStock: int.parse(_minStockController.text),
        unitType: _selectedUnitType,
        categoryId: _selectedCategoryId,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await Provider.of<ProductProvider>(context, listen: false).createProduct(product);

      if (success && mounted) {
        Fluttertoast.showToast(msg: 'Product added successfully', backgroundColor: Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Add Product'), backgroundColor: AppTheme.surfaceDark),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImageUrlSection(),
            const SizedBox(height: 24),
            _buildSection('Basic Info', Icons.info_outline, [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.shopping_bag, color: AppTheme.primaryGreen)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name too short';
                  if (v.trim().length > 50) return 'Name too long (max 50)';
                  return null;
                },
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'SKU / Barcode', prefixIcon: Icon(Icons.qr_code, color: AppTheme.primaryGreen)),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Pricing', Icons.attach_money, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Selling Price *', prefixIcon: Icon(Icons.sell, color: AppTheme.primaryGreen)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final p = double.tryParse(v);
                        if (p == null) return 'Invalid';
                        if (p <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cost Price', prefixIcon: Icon(Icons.money_off, color: AppTheme.primaryGreen)),
                      validator: (v) {
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_projectedMargin != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Margin: ${_projectedMargin!.toStringAsFixed(1)}%', 
                    style: TextStyle(color: _projectedMargin! > 0 ? AppTheme.primaryGreen : Colors.red, fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Inventory', Icons.inventory_2_outlined, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Current Stock *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Level *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Save Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, color: AppTheme.primaryGreen, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildImageUrlSection() {
    final imageUrl = _imageUrlController.text.trim();
    return Column(
      children: [
        TextFormField(
          controller: _imageUrlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Image URL (Optional)', prefixIcon: Icon(Icons.image, color: AppTheme.primaryGreen)),
        ),
        if (Validators.isValidImageUrl(imageUrl))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, height: 100, width: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey))),
          ),
      ],
    );
  }
}
