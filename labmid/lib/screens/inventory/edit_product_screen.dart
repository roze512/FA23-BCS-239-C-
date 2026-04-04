import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../utils/validators.dart';

/// Edit Product Screen - Update existing product
class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _minStockController;
  late TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  String _selectedUnitType = 'item';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing product data
    _nameController = TextEditingController(text: widget.product.name);
    _skuController = TextEditingController(text: widget.product.sku ?? '');
    _descriptionController = TextEditingController(text: widget.product.description ?? '');
    _priceController = TextEditingController(text: widget.product.price.toString());
    _costPriceController = TextEditingController(text: widget.product.costPrice?.toString() ?? '');
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _minStockController = TextEditingController(text: widget.product.minStock.toString());
    _imageUrlController = TextEditingController(text: widget.product.imageUrl ?? '');
    _selectedCategoryId = widget.product.categoryId;
    _selectedUnitType = widget.product.unitType;

    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
    
    // Listen for image URL changes to update preview
    _imageUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: 'Please fill all required fields',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = _imageUrlController.text.trim();
      final updatedProduct = ProductModel(
        id: widget.product.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        barcode: widget.product.barcode,
        price: double.parse(_priceController.text),
        costPrice: _costPriceController.text.isEmpty ? null : double.parse(_costPriceController.text),
        quantity: int.parse(_quantityController.text),
        minStock: int.parse(_minStockController.text),
        unitType: _selectedUnitType,
        categoryId: _selectedCategoryId,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: 0,
      );

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.updateProduct(updatedProduct);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Product updated successfully',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update product: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: const Text('Edit Product', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStep(),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          _buildStepCircle(0, 'Details'),
          Expanded(child: _buildStepLine(0)),
          _buildStepCircle(1, 'Pricing'),
          Expanded(child: _buildStepLine(1)),
          _buildStepCircle(2, 'Inventory'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? AppTheme.primaryGreen : AppTheme.surfaceDark,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted ? AppTheme.primaryGreen : AppTheme.borderDark,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppTheme.backgroundDark, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive || isCompleted ? AppTheme.backgroundDark : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? AppTheme.primaryGreen : AppTheme.borderDark,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildPricingStep();
      case 2:
        return _buildInventoryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsStep() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1/3 - Product Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildImageUrlSection(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'Enter product name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'SKU/Barcode',
                hintText: 'Enter SKU or scan barcode',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen),
                  onPressed: () {
                    // TODO: Implement barcode scanner
                    Fluttertoast.showToast(msg: 'Barcode scanner coming soon');
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              dropdownColor: AppTheme.surfaceDark,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'Select category',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Category', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ...categoryProvider.categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name, style: const TextStyle(color: Colors.white)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter product description',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2/3 - Pricing',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _priceController,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Selling Price *',
            hintText: 'Enter selling price',
            prefixText: '\$ ',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Selling price is required';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _costPriceController,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cost Price',
            hintText: 'Enter cost price',
            prefixText: '\$ ',
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 24),
        if (_priceController.text.isNotEmpty && _costPriceController.text.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projected Margin',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    Text(
                      '${_calculateMargin().toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _calculateMargin() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final cost = double.tryParse(_costPriceController.text) ?? 0;
    if (price > 0 && cost > 0) {
      return ((price - cost) / price * 100);
    }
    return 0;
  }

  Widget _buildInventoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3/3 - Inventory',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Stock Quantity',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: () {
                final currentQty = int.tryParse(_quantityController.text) ?? 0;
                if (currentQty > 0) {
                  _quantityController.text = (currentQty - 1).toString();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.primaryGreen,
              iconSize: 32,
            ),
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              onPressed: () {
                final currentQty = int.tryParse(_quantityController.text) ?? 0;
                _quantityController.text = (currentQty + 1).toString();
                setState(() {});
              },
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryGreen,
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _minStockController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minimum Stock Level',
            hintText: 'Alert when stock falls below this',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Minimum stock level is required';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedUnitType,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Unit Type',
          ),
          items: const [
            DropdownMenuItem(value: 'item', child: Text('Item', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'weight', child: Text('Weight (kg)', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'volume', child: Text('Volume (L)', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'box', child: Text('Box', style: TextStyle(color: Colors.white))),
          ],
          onChanged: (value) {
            setState(() {
              _selectedUnitType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        _saveProduct();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.backgroundDark),
                      ),
                    )
                  : Text(_currentStep < 2 ? 'Next' : 'Update Product'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUrlSection() {
    final imageUrl = _imageUrlController.text.trim();
    final hasValidUrl = Validators.isValidImageUrl(imageUrl);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image_outlined, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Product Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Image URL Text Field
        TextFormField(
          controller: _imageUrlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Image URL (Optional)',
            hintText: 'https://example.com/image.jpg',
            prefixIcon: Icon(Icons.link, color: AppTheme.textSecondary),
            helperText: 'Enter a valid image URL to display product image',
            helperMaxLines: 2,
          ),
          keyboardType: TextInputType.url,
          maxLines: 2,
        ),
        
        // Image Preview
        if (hasValidUrl) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderDark.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryGreen,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}