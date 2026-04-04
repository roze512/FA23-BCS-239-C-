import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale_model.dart';
import 'sales_service.dart';

/// Service for generating and exporting reports
class ReportService {
  final SalesService _salesService = SalesService();

  /// Calculate sales report with null safety
  Future<Map<String, dynamic>> calculateSalesReport(DateTime start, DateTime end) async {
    try {
      final sales = await _salesService.getSalesInRange(start, end);
      
      // Handle null/empty sales
      if (sales.isEmpty) {
        return {
          'totalSales': 0.0,
          'totalOrders': 0,
          'averageOrderValue': 0.0,
          'topProducts': <Map<String, dynamic>>[],
          'error': null,
        };
      }
      
      double totalSales = 0.0;
      int totalOrders = sales.length;
      
      for (final sale in sales) {
        // Safely parse total with null check
        totalSales += sale.total;
      }
      
      return {
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0.0,
        'topProducts': _calculateTopProducts(sales),
        'error': null,
      };
    } catch (e) {
      debugPrint('Error calculating report: $e');
      return {
        'totalSales': 0.0,
        'totalOrders': 0,
        'averageOrderValue': 0.0,
        'topProducts': <Map<String, dynamic>>[],
        'error': 'Failed to load report: ${e.toString()}',
      };
    }
  }

  /// Calculate top products from sales
  List<Map<String, dynamic>> _calculateTopProducts(List<SaleModel> sales) {
    try {
      final productMap = <String, Map<String, dynamic>>{};
      
      for (final sale in sales) {
        for (final item in sale.items) {
          final productId = item.productId;
          if (productMap.containsKey(productId)) {
            productMap[productId]!['quantity'] += item.quantity;
            productMap[productId]!['revenue'] += item.total;
          } else {
            productMap[productId] = {
              'productId': productId,
              'productName': item.productName,
              'quantity': item.quantity,
              'revenue': item.total,
            };
          }
        }
      }
      
      // Sort by quantity and take top 10
      final sortedProducts = productMap.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
      
      return sortedProducts.take(10).toList();
    } catch (e) {
      debugPrint('Error calculating top products: $e');
      return [];
    }
  }

  /// Export report to CSV format
  Future<String> exportReportToCSV(DateTime start, DateTime end) async {
    try {
      final report = await calculateSalesReport(start, end);
      
      if (report['error'] != null) {
        throw Exception(report['error']);
      }
      
      final buffer = StringBuffer();
      buffer.writeln('Sales Report');
      buffer.writeln('Period: ${start.toString()} to ${end.toString()}');
      buffer.writeln('');
      buffer.writeln('Total Sales,${report['totalSales']}');
      buffer.writeln('Total Orders,${report['totalOrders']}');
      buffer.writeln('Average Order Value,${report['averageOrderValue']}');
      buffer.writeln('');
      buffer.writeln('Top Products:');
      buffer.writeln('Product Name,Quantity,Revenue');
      
      final topProductsList = report['topProducts'];
      if (topProductsList is List) {
        for (final product in topProductsList) {
          if (product is Map<String, dynamic>) {
            buffer.writeln('${product['productName']},${product['quantity']},${product['revenue']}');
          }
        }
      }
      
      return buffer.toString();
    } catch (e) {
      throw Exception('Failed to export report: ${e.toString()}');
    }
  }

  /// Email report
  Future<void> emailReport(String email, DateTime start, DateTime end) async {
    try {
      final reportData = await exportReportToCSV(start, end);
      
      // Format dates properly
      final startDate = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final subject = Uri.encodeComponent('Sales Report - $startDate');
      final body = Uri.encodeComponent(reportData);
      
      final emailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not open email app');
      }
    } catch (e) {
      throw Exception('Failed to email report: ${e.toString()}');
    }
  }
}
