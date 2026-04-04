import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../services/sales_service.dart';
import '../../services/report_service.dart';
import '../../services/product_service.dart';
import '../../services/customer_service.dart';
import '../../utils/format_helper.dart';
import '../../models/sale_model.dart';
import '../../models/product_model.dart';
import '../../models/customer_model.dart';

/// Reports screen with KPI cards and detailed reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SalesService _salesService = SalesService();
  final ReportService _reportService = ReportService();
  
  String _selectedPeriod = 'Today';
  double _totalSales = 0.0;
  double _grossProfit = 0.0;
  int _totalOrders = 0;
  
  double _salesChange = 0.0;
  double _profitChange = 0.0;
  double _ordersChange = 0.0;
  
  bool _isLoading = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setPeriod('Today');
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }

    setState(() {
      _selectedPeriod = period;
      _startDate = start;
      _endDate = end;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentSales = await _salesService.getSalesTotal(_startDate, _endDate);
      final currentProfit = await _salesService.getGrossProfit(_startDate, _endDate);
      final currentOrders = await _salesService.getOrderCount(_startDate, _endDate);
      
      final duration = _endDate.difference(_startDate);
      final prevStart = _startDate.subtract(duration + const Duration(seconds: 1));
      final prevEnd = _startDate.subtract(const Duration(seconds: 1));
      
      final prevSales = await _salesService.getSalesTotal(prevStart, prevEnd);
      final prevProfit = await _salesService.getGrossProfit(prevStart, prevEnd);
      final prevOrders = await _salesService.getOrderCount(prevStart, prevEnd);
      
      setState(() {
        _totalSales = currentSales;
        _grossProfit = currentProfit;
        _totalOrders = currentOrders;
        
        _salesChange = prevSales > 0 ? ((currentSales - prevSales) / prevSales) * 100 : (currentSales > 0 ? 100 : 0);
        _profitChange = prevProfit > 0 ? ((currentProfit - prevProfit) / prevProfit) * 100 : (currentProfit > 0 ? 100 : 0);
        _ordersChange = prevOrders > 0 ? ((currentOrders - prevOrders) / prevOrders.toDouble()) * 100 : (currentOrders > 0 ? 100 : 0);
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Analytics & Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateFilter(),
                  const SizedBox(height: 20),
                  _buildKPICards(),
                  const SizedBox(height: 24),
                  _buildDetailedReportsList(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: () => _showPeriodSelector(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedPeriod, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${FormatHelper.formatDate(_startDate)} - ${FormatHelper.formatDate(_endDate)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.tune, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return Column(
      children: [
        _buildKPICard(
          title: 'Total Revenue',
          value: FormatHelper.formatMoney(_totalSales),
          trend: _salesChange,
          color: AppTheme.primaryBlue,
          icon: Icons.payments,
        ),
        const SizedBox(height: 12),
        _buildKPICard(
          title: 'Gross Profit',
          value: FormatHelper.formatMoney(_grossProfit),
          trend: _profitChange,
          color: AppTheme.primaryGreen,
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        _buildKPICard(
          title: 'Total Orders',
          value: _totalOrders.toString(),
          trend: _ordersChange,
          color: Colors.purple,
          icon: Icons.shopping_basket,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required double trend,
    required Color color,
    required IconData icon,
  }) {
    final isPositive = trend >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? AppTheme.primaryGreen : Colors.red, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${trend.abs().toStringAsFixed(1)}%',
                    style: TextStyle(color: isPositive ? AppTheme.primaryGreen : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const Text('vs prev', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReportsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detailed Analytics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildReportItem(
          icon: Icons.query_stats,
          color: AppTheme.primaryBlue,
          title: 'Daily Sales Performance',
          subtitle: 'Hourly breakdown and peak times',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DailySalesReportScreen(startDate: _startDate, endDate: _endDate))),
        ),
        _buildReportItem(
          icon: Icons.inventory_2,
          color: AppTheme.primaryGreen,
          title: 'Inventory Status',
          subtitle: 'Low stock alerts and movements',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockReportScreen())),
        ),
        _buildReportItem(
          icon: Icons.stars,
          color: Colors.purple,
          title: 'Customer Insights',
          subtitle: 'Top buyers and loyalty data',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerInsightsScreen(startDate: _startDate, endDate: _endDate))),
        ),
        _buildReportItem(
          icon: Icons.analytics,
          color: Colors.orange,
          title: 'Profit & Loss Statement',
          subtitle: 'Comprehensive financial breakdown',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfitLossReportScreen(startDate: _startDate, endDate: _endDate))),
        ),
      ],
    );
  }

  Widget _buildReportItem({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.borderDark)),
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 14),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionButton(icon: Icons.file_download, label: 'Export CSV', onTap: () => _exportCSV())),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(icon: Icons.share, label: 'Share Report', onTap: () => _emailReport())),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
        foregroundColor: AppTheme.primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppTheme.primaryGreen, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Time Period', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['Today', 'This Week', 'This Month', 'This Year', 'Custom Range'].map((p) => ListTile(
                  leading: Icon(_selectedPeriod == p ? Icons.radio_button_checked : Icons.radio_button_off, color: AppTheme.primaryGreen),
                  title: Text(p, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    if (p == 'Custom Range') {
                      _selectDateRange();
                    } else {
                      _setPeriod(p);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primaryGreen, onPrimary: Colors.black, surface: AppTheme.surfaceDark, onSurface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom Range';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _loadData();
    }
  }

  Future<void> _exportCSV() async {
    try {
      final csv = await _reportService.exportReportToCSV(_startDate, _endDate);
      Fluttertoast.showToast(msg: 'Report Exported Successfully', backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Export Failed: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _emailReport() async {
    Fluttertoast.showToast(msg: 'Sharing options coming soon');
  }
}

// --- FULLY IMPLEMENTED DETAILED REPORT SCREENS ---

class DailySalesReportScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const DailySalesReportScreen({super.key, required this.startDate, required this.endDate});

  @override
  State<DailySalesReportScreen> createState() => _DailySalesReportScreenState();
}

class _DailySalesReportScreenState extends State<DailySalesReportScreen> {
  final SalesService _salesService = SalesService();
  List<SaleModel> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final sales = await _salesService.getSalesInRange(widget.startDate, widget.endDate);
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Sales Performance'),
        backgroundColor: AppTheme.surfaceDark,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${FormatHelper.formatDate(widget.startDate)} - ${FormatHelper.formatDate(widget.endDate)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
        : _sales.isEmpty 
          ? const Center(child: Text('No sales found for this period', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderDark)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.receipt_long, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sale.invoiceNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${sale.createdAt.hour}:${sale.createdAt.minute.toString().padLeft(2, "0")} • ${sale.customerName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(FormatHelper.formatMoney(sale.total), style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});
  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final ProductService _productService = ProductService();
  List<ProductModel> _lowStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    final lowStock = await _productService.getLowStockProducts();
    setState(() {
      _lowStockProducts = lowStock;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Inventory Status'), backgroundColor: AppTheme.surfaceDark),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppTheme.surfaceDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Low Stock Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${_lowStockProducts.length} items require attention', style: TextStyle(color: _lowStockProducts.isNotEmpty ? Colors.red : AppTheme.primaryGreen)),
                  ],
                ),
              ),
              Expanded(
                child: _lowStockProducts.isEmpty 
                  ? const Center(child: Text('All stock levels are healthy!', style: TextStyle(color: AppTheme.primaryGreen)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _lowStockProducts.length,
                      itemBuilder: (context, index) {
                        final product = _lowStockProducts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderDark)),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text('Min Level: ${product.minStock}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('${product.quantity} left', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}

class CustomerInsightsScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const CustomerInsightsScreen({super.key, required this.startDate, required this.endDate});

  @override
  State<CustomerInsightsScreen> createState() => _CustomerInsightsScreenState();
}

class _CustomerInsightsScreenState extends State<CustomerInsightsScreen> {
  final SalesService _salesService = SalesService();
  Map<String, double> _customerSpending = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final sales = await _salesService.getSalesInRange(widget.startDate, widget.endDate);
    final Map<String, double> insights = {};
    for (var sale in sales) {
      insights[sale.customerName] = (insights[sale.customerName] ?? 0.0) + sale.total;
    }
    // Sort by spending
    final sorted = Map.fromEntries(insights.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    
    setState(() {
      _customerSpending = sorted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Customer Analytics'), backgroundColor: AppTheme.surfaceDark),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
        : _customerSpending.isEmpty 
          ? const Center(child: Text('No data found for this period', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _customerSpending.length,
              itemBuilder: (context, index) {
                final entry = _customerSpending.entries.elementAt(index);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderDark)),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.purple.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.purple)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Text(FormatHelper.formatMoney(entry.value), style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class ProfitLossReportScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  const ProfitLossReportScreen({super.key, required this.startDate, required this.endDate});

  @override
  State<ProfitLossReportScreen> createState() => _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState extends State<ProfitLossReportScreen> {
  final SalesService _salesService = SalesService();
  double _revenue = 0.0;
  double _cost = 0.0;
  double _profit = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPAndL();
  }

  Future<void> _loadPAndL() async {
    final revenue = await _salesService.getSalesTotal(widget.startDate, widget.endDate);
    final profit = await _salesService.getGrossProfit(widget.startDate, widget.endDate);
    setState(() {
      _revenue = revenue;
      _profit = profit;
      _cost = revenue - profit;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Profit & Loss Statement'), backgroundColor: AppTheme.surfaceDark),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPLRow('Gross Revenue', _revenue, Colors.white),
                const Divider(color: AppTheme.borderDark),
                _buildPLRow('Cost of Goods Sold', -_cost, Colors.red),
                const Divider(color: AppTheme.borderDark, thickness: 2),
                _buildPLRow('Net Profit', _profit, AppTheme.primaryGreen, isBold: true),
                const SizedBox(height: 32),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: _profit, title: 'Profit', color: AppTheme.primaryGreen, radius: 50, titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        PieChartSectionData(value: _cost, title: 'Cost', color: Colors.red, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPLRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(FormatHelper.formatMoney(value), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
