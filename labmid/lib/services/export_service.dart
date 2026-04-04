import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'sales_service.dart';
import 'product_service.dart';
import 'customer_service.dart';

/// Service for exporting reports to PDF and email
class ExportService {
  final SalesService _salesService = SalesService();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();

  /// Generate comprehensive report PDF
  Future<File> generateReportPDF() async {
    final pdf = pw.Document();
    
    // Get data
    final sales = await _salesService.getAllSales();
    final products = await _productService.getAllProducts();
    final customers = await _customerService.getCustomers();
    
    // Calculate totals
    final totalSales = sales.fold<double>(0.0, (sum, sale) => sum + sale.total);
    final totalOrders = sales.length;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SmartPOS Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated on ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Sales Summary
          pw.Header(
            level: 1,
            text: 'Sales Summary',
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total Sales: \$${totalSales.toStringAsFixed(2)}'),
          pw.Text('Total Orders: $totalOrders'),
          pw.Text('Average Order Value: \$${(totalOrders > 0 ? totalSales / totalOrders : 0).toStringAsFixed(2)}'),
          
          pw.SizedBox(height: 20),
          
          // Inventory Summary
          pw.Header(
            level: 1,
            text: 'Inventory Summary',
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total Products: ${products.length}'),
          pw.Text('Low Stock Items: ${products.where((p) => p.isLowStock).length}'),
          pw.Text('Out of Stock: ${products.where((p) => p.quantity == 0).length}'),
          
          pw.SizedBox(height: 20),
          
          // Customer Summary
          pw.Header(
            level: 1,
            text: 'Customer Summary',
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total Customers: ${customers.length}'),
          pw.Text('Total Customers: ${customers.length}'),
          
          pw.SizedBox(height: 20),
          
          // Recent Sales Table
          pw.Header(
            level: 1,
            text: 'Recent Sales (Last 10)',
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Invoice', 'Customer', 'Total', 'Date'],
            data: sales.take(10).map((sale) => [
              sale.invoiceNumber,
              sale.customerName,
              '\$${sale.total.toStringAsFixed(2)}',
              sale.createdAt.toString().split(' ')[0],
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );
    
    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/SmartPOS_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  /// Export and open PDF
  Future<void> exportPDF() async {
    try {
      final file = await generateReportPDF();
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }
  
  /// Email report
  Future<void> emailReport() async {
    try {
      final file = await generateReportPDF();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SmartPOS Report',
        text: 'Please find attached the SmartPOS report generated on ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      throw Exception('Failed to email report: $e');
    }
  }
}
