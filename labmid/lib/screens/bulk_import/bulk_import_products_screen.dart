import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../config/theme.dart';

class BulkImportProductsScreen extends StatefulWidget {
  const BulkImportProductsScreen({super.key});

  @override
  State<BulkImportProductsScreen> createState() => _BulkImportProductsScreenState();
}

class _BulkImportProductsScreenState extends State<BulkImportProductsScreen> {
  bool _isLoading = false;
  int _importedCount = 0;
  final ProductService _productService = ProductService();

  // ✅ Export Template Excel to Downloads/Recent
  Future<void> _exportTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      var excel = Excel.createExcel();
      
      // Remove default "Sheet1" that is created automatically
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }
      
      Sheet sheet = excel['Products'];
      
      // Add headers
      sheet.appendRow([
        TextCellValue('Name*'),
        TextCellValue('Category'),
        TextCellValue('Barcode/SKU'),
        TextCellValue('Purchase Price'),
        TextCellValue('Selling Price*'),
        TextCellValue('Stock Quantity*'),
        TextCellValue('Min Stock Level'),
        TextCellValue('Description'),
        TextCellValue('Image URL'),
      ]);
      
      // Add example row
      sheet.appendRow([
        TextCellValue('Product Name'),
        TextCellValue('Electronics'),
        TextCellValue('SKU123'),
        TextCellValue('100'),
        TextCellValue('150'),
        TextCellValue('50'),
        TextCellValue('10'),
        TextCellValue('Product description'),
        TextCellValue('https://example.com/image.jpg'),
      ]);
      
      final bytes = excel.encode();
      if (bytes == null) throw Exception("Failed to encode excel");

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/product_template.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes);
      
      // Use Share to let user save it to Downloads or open it
      await Share.shareXFiles([XFile(path)], text: 'Product Import Template');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template ready! Please save it to your device.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Import Excel File
  Future<void> _importExcel() async {
    setState(() => _isLoading = true);
    _importedCount = 0;
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      
      if (result != null) {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        if (!mounted) return;
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        await categoryProvider.loadCategories();
        final categories = categoryProvider.categories;
        
        if (excel.tables.isEmpty) throw Exception('Excel file is empty');
        
        // Take ONLY the first sheet
        var sheetName = excel.tables.keys.first;
        var sheet = excel.tables[sheetName]!;
        
        if (sheet.maxRows == 0) throw Exception('Sheet is empty');
        
        // Validate headers
        var headerRow = sheet.row(0);
        if (headerRow.isEmpty || 
            headerRow[0]?.value?.toString() != 'Name*' || 
            headerRow[4]?.value?.toString() != 'Selling Price*') {
          throw Exception('Invalid template format. Please export and use the provided template.');
        }
          
        // Skip header row (index 0)
        for (int i = 1; i < sheet.maxRows; i++) {
          try {
            var row = sheet.row(i);
            
            // Validate required fields (Name, Selling Price, Quantity)
            if (row.isEmpty || row[0]?.value == null || row[4]?.value == null || row[5]?.value == null) {
              continue; // Skip invalid or empty rows
            }
            
            // Category mapping validation
            String? categoryName = row[1]?.value?.toString();
            String? mappedCategoryId;
            
            if (categoryName != null && categoryName.trim().isNotEmpty) {
              final matchingCategories = categories.where(
                (c) => c.name.toLowerCase() == categoryName.trim().toLowerCase()
              ).toList();
              
              if (matchingCategories.isNotEmpty) {
                mappedCategoryId = matchingCategories.first.id;
              } else {
                throw Exception('Category "${categoryName.trim()}" in row ${i + 1} does not exist. Please create it first.');
              }
            }
            
            final product = ProductModel(
              id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
              name: row[0]?.value?.toString().trim() ?? '',
              categoryId: mappedCategoryId,
              barcode: row[2]?.value?.toString().trim(),
              costPrice: double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0,
              price: double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0,
              quantity: int.tryParse(row[5]?.value?.toString() ?? '0') ?? 0,
              minStock: int.tryParse(row[6]?.value?.toString() ?? '5') ?? 5,
              description: row[7]?.value?.toString().trim(),
              imageUrl: row[8]?.value?.toString().trim(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _productService.createProduct(product);
            _importedCount++;
          } catch (e) {
            // Rethrow specific validation errors to stop the whole import
            if (e.toString().contains('Category')) {
              rethrow;
            }
            debugPrint('Error importing row $i: $e');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $_importedCount products!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context, true); // Refresh parent
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('Bulk Import Products'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppTheme.primaryGreen)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file, size: 100, color: Colors.blue),
                    const SizedBox(height: 32),
                    const Text(
                      'Bulk Import Products',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '1. Export Excel template\n2. Fill product details\n3. Import filled Excel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _exportTemplate,
                        icon: const Icon(Icons.download),
                        label: const Text('1. Export Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _importExcel,
                        icon: const Icon(Icons.upload),
                        label: const Text('2. Import Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
