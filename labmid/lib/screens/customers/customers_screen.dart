import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';
import '../../widgets/customer_avatar.dart';
import '../../utils/format_helper.dart';
import 'add_customer_screen.dart';
import 'customer_detail_sheet.dart';

/// Customer list screen with filters
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
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
        automaticallyImplyLeading: false,
        title: const Text('Customers', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
              ).then((_) => _loadCustomers());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildCustomerList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          Provider.of<CustomerProvider>(context, listen: false).setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        final filters = [
          {'label': 'All Customers', 'value': 'all'},
          {'label': 'Active', 'value': 'active'},
          {'label': 'Debtors', 'value': 'debtors'},
          {'label': 'Credit', 'value': 'credit'},
          {'label': 'Inactive', 'value': 'inactive'},
        ];

        return SizedBox(
          height: 50,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = customerProvider.filterType == filter['value'];

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    customerProvider.setFilter(filter['value']!);
                  },
                  backgroundColor: AppTheme.surfaceDark,
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: isSelected 
                        ? AppTheme.primaryGreen 
                        : AppTheme.borderDark.withOpacity(0.5),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCustomerList() {
    return Expanded(
      child: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          if (customerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            );
          }

          final customers = customerProvider.filteredCustomers;

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No customers found',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Name / Contact',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Balance',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Customer list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadCustomers,
                  color: AppTheme.primaryGreen,
                  backgroundColor: AppTheme.surfaceDark,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) => _buildCustomerCard(customers[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    Color balanceColor;
    String balanceStatus;
    
    if (customer.isDebtor) {
      balanceColor = AppTheme.alertRed;
      balanceStatus = 'Pending';
    } else if (customer.hasCredit) {
      balanceColor = AppTheme.primaryBlue;
      balanceStatus = 'Credit';
    } else {
      balanceColor = AppTheme.textSecondary;
      balanceStatus = 'Settled';
    }

    final isInactive = !customer.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CustomerDetailSheet(customer: customer),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isInactive 
                ? AppTheme.surfaceDark.withOpacity(0.5) 
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              // Avatar
              Opacity(
                opacity: isInactive ? 0.5 : 1.0,
                child: CustomerAvatar(
                  imageUrl: customer.photoUrl,
                  name: customer.name,
                  radius: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            color: isInactive ? AppTheme.textSecondary : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isInactive) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(Inactive)',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                      Text(
                        customer.phone!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FormatHelper.formatMoney(customer.balance.abs(), showSign: customer.balance != 0),
                    style: TextStyle(
                      color: balanceColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: balanceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      balanceStatus,
                      style: TextStyle(
                        color: balanceColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
