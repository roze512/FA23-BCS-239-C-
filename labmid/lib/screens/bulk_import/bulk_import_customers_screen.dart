import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';
import '../../config/theme.dart';

class BulkImportCustomersScreen extends StatefulWidget {
  const BulkImportCustomersScreen({super.key});

  @override
  State<BulkImportCustomersScreen> createState() => _BulkImportCustomersScreenState();
}

class _BulkImportCustomersScreenState extends State<BulkImportCustomersScreen> {
  bool _isLoading = false;
  int _importedCount = 0;
  final CustomerService _customerService = CustomerService();

  // ✅ Export Template Excel to Recent/Downloads
  Future<void> _exportTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Customers'];
      
      // Add headers
      sheet.appendRow([
        TextCellValue('Name*'),
        TextCellValue('Phone*'),
        TextCellValue('Email'),
        TextCellValue('Address'),
        TextCellValue('City'),
        TextCellValue('Active Status* (Yes/No)'),
      ]);
      
      // Add example row
      sheet.appendRow([
        TextCellValue('John Doe'),
        TextCellValue('1234567890'),
        TextCellValue('john@example.com'),
        TextCellValue('123 Main St'),
        TextCellValue('New York'),
        TextCellValue('Yes'),
      ]);
      
      final bytes = excel.encode();
      if (bytes == null) throw Exception("Failed to encode excel");

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/customer_template.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes);
      
      // Use Share to let user save it to Downloads or open it
      await Share.shareXFiles([XFile(path)], text: 'Customer Import Template');
      
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
        
        if (excel.tables.isEmpty) throw Exception('Excel file is empty');
        
        // Take ONLY the first sheet
        var sheetName = excel.tables.keys.first;
        var sheet = excel.tables[sheetName]!;
        
        if (sheet.maxRows == 0) throw Exception('Sheet is empty');
        
        // Validate headers
        var headerRow = sheet.row(0);
        if (headerRow.isEmpty || 
            headerRow[0]?.value?.toString() != 'Name*' || 
            headerRow[1]?.value?.toString() != 'Phone*') {
          throw Exception('Invalid template format. Please export and use the provided template.');
        }
          
        // Skip header row (index 0)
        for (int i = 1; i < sheet.maxRows; i++) {
          try {
            var row = sheet.row(i);
            
            // Validate required fields (Name, Phone, Active Status)
            if (row.isEmpty || row[0]?.value == null || row[1]?.value == null || row[5]?.value == null) {
              continue; // Skip invalid rows
            }
            
            // Parse active status (Yes/No or true/false)
            final activeStr = row[5]?.value?.toString().toLowerCase().trim() ?? 'yes';
            final isActive = activeStr == 'yes' || activeStr == 'true' || activeStr == '1';
            
            final customer = CustomerModel(
              id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
              name: row[0]?.value?.toString().trim() ?? '',
              phone: row[1]?.value?.toString().trim() ?? '',
              email: row[2]?.value?.toString().trim(),
              address: row[3]?.value?.toString().trim(),
              city: row[4]?.value?.toString().trim(),
              isActive: isActive,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await _customerService.addCustomer(customer);
            _importedCount++;
          } catch (e) {
            debugPrint('Error importing row $i: $e');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $_importedCount customers!'),
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
        title: const Text('Bulk Import Customers'),
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
                    const Icon(Icons.group_add, size: 100, color: Colors.purple),
                    const SizedBox(height: 32),
                    const Text(
                      'Bulk Import Customers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '1. Export Excel template\n2. Fill customer details\n3. Import filled Excel',
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
