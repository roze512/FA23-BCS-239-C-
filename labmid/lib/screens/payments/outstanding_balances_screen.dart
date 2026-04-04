import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';
import '../../widgets/customer_avatar.dart';
import '../../utils/format_helper.dart';
import 'ledger_adjustment_screen.dart';

/// Outstanding Balances Screen - Shows customers with balances
class OutstandingBalancesScreen extends StatefulWidget {
  const OutstandingBalancesScreen({super.key});

  @override
  State<OutstandingBalancesScreen> createState() => _OutstandingBalancesScreenState();
}

class _OutstandingBalancesScreenState extends State<OutstandingBalancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    await customerProvider.loadCustomers();
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
        title: const Text(
          'Outstanding Balances',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final allCustomers = customerProvider.customers;
          
          // Calculate totals
          final receivables = allCustomers.where((c) => c.balance < 0).toList();
          final credits = allCustomers.where((c) => c.balance > 0).toList();
          
          final totalReceivables = receivables.fold<double>(
            0.0, (sum, c) => sum + c.balance.abs()
          );
          
          final totalCredits = credits.fold<double>(
            0.0, (sum, c) => sum + c.balance
          );

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(receivables.length, totalReceivables, credits.length, totalCredits),
              
              // Tabs
              Container(
                color: AppTheme.surfaceDark,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryGreen,
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: const [
                    Tab(text: 'Receivables'),
                    Tab(text: 'Credits'),
                  ],
                ),
              ),
              
              // Search Bar
              _buildSearchBar(),
              
              // Customer List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCustomerList(receivables, isReceivable: true),
                    _buildCustomerList(credits, isReceivable: false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(int receivableCount, double totalReceivables, int creditCount, double totalCredits) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Receivables',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  FormatHelper.formatMoney(totalReceivables),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$receivableCount Customers',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Credits',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  FormatHelper.formatMoney(totalCredits),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$creditCount Customers',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search customer by name...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCustomerList(List<CustomerModel> customers, {required bool isReceivable}) {
    // Filter by search
    var filteredCustomers = customers;
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredCustomers = customers.where((c) => 
        c.name.toLowerCase().contains(query)
      ).toList();
    }

    if (filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isReceivable ? 'receivables' : 'credits'}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCustomers.length,
      itemBuilder: (context, index) {
        return _buildCustomerCard(filteredCustomers[index], isReceivable: isReceivable);
      },
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, {required bool isReceivable}) {
    final balanceColor = isReceivable ? AppTheme.alertRed : AppTheme.primaryGreen;
    final balanceAmount = customer.balance.abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Avatar with photo support
          CustomerAvatar(
            imageUrl: customer.photoUrl,
            name: customer.name,
            radius: 24,
          ),
          const SizedBox(width: 12),
          
          // Customer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (customer.phone != null)
                  Text(
                    customer.phone!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          
          // Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatHelper.formatMoney(balanceAmount),
                style: TextStyle(
                  color: balanceColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LedgerAdjustmentScreen(
                        customerId: customer.id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pay',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
