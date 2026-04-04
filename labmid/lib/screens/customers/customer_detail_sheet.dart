import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../utils/format_helper.dart';
import '../../widgets/customer_avatar.dart';
import 'edit_customer_screen.dart';

class CustomerDetailSheet extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailSheet({super.key, required this.customer});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Customer', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCustomer(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.alertRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(BuildContext context) async {
    try {
      await Provider.of<CustomerProvider>(context, listen: false).deleteCustomer(customer.id);
      if (context.mounted) {
        Navigator.pop(context); // Close the bottom sheet
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceColor = customer.isDebtor 
        ? AppTheme.alertRed 
        : customer.hasCredit 
            ? AppTheme.primaryBlue 
            : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header info
          Row(
            children: [
              CustomerAvatar(
                imageUrl: customer.photoUrl,
                name: customer.name,
                radius: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Text(
                        customer.phone!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: customer.isActive 
                            ? AppTheme.primaryGreen.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        customer.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: customer.isActive ? AppTheme.primaryGreen : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: AppTheme.borderDark, height: 1),
          const SizedBox(height: 24),
          
          // Details Grid
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Balance',
                  FormatHelper.formatMoney(customer.balance.abs(), showSign: customer.balance != 0),
                  color: balanceColor,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Status',
                  customer.isDebtor ? 'Pending' : customer.hasCredit ? 'Credit' : 'Settled',
                  color: balanceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'City',
                  customer.city?.isNotEmpty == true ? customer.city! : 'N/A',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Joined',
                  customer.createdAt != null 
                      ? FormatHelper.formatDate(customer.createdAt!) 
                      : 'Unknown',
                ),
              ),
            ],
          ),
          if (customer.address != null && customer.address!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailItem('Address', customer.address!),
          ],
          if (customer.email != null && customer.email!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailItem('Email', customer.email!),
          ],
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_outline, color: AppTheme.alertRed),
                  label: const Text('Delete', style: TextStyle(color: AppTheme.alertRed)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.alertRed.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCustomerScreen(customer: customer),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text('Edit Customer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // SafeArea padding
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
