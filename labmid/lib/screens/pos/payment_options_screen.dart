import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/customer_model.dart';
import '../../utils/format_helper.dart';
import 'receipt_screen.dart';

/// Payment options screen
class PaymentOptionsScreen extends StatelessWidget {
  final CustomerModel? customer;
  final bool isWalkIn;

  const PaymentOptionsScreen({
    super.key,
    this.customer,
    required this.isWalkIn,
  });

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
        title: const Text('Payment Options', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer3<CartProvider, AuthProvider, SalesProvider>(
        builder: (context, cartProvider, authProvider, salesProvider, child) {
          return Column(
            children: [
              const SizedBox(height: 32),
              
              // Customer Section
              _buildCustomerSection(),
              
              const SizedBox(height: 24),
              
              // Previous Balance (if exists)
              if (customer != null && customer!.balance != 0)
                _buildPreviousBalance(context),
              
              // Total to Pay
              _buildTotalSection(context, cartProvider),
              
              const SizedBox(height: 32),
              
              // Payment Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Pay Now Button
                    ElevatedButton.icon(
                      onPressed: () => _handlePayNow(
                        context,
                        cartProvider,
                        authProvider,
                        salesProvider,
                        'cash',
                      ),
                      icon: const Icon(Icons.payments),
                      label: const Text(
                        'PAY NOW',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Add to Credit Button
                    OutlinedButton.icon(
                      onPressed: isWalkIn
                          ? null
                          : () => _handlePayNow(
                                context,
                                cartProvider,
                                authProvider,
                                salesProvider,
                                'credit',
                              ),
                      icon: const Icon(Icons.credit_score),
                      label: Column(
                        children: [
                          const Text(
                            'Add to Credit',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isWalkIn ? 'Not available for walk-in' : 'Pay Later',
                            style: TextStyle(
                              fontSize: 12,
                              color: isWalkIn ? AppTheme.textSecondary : AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isWalkIn ? AppTheme.textSecondary : AppTheme.primaryGreen,
                        side: BorderSide(
                          color: isWalkIn 
                              ? AppTheme.textSecondary.withValues(alpha: 0.3) 
                              : AppTheme.primaryGreen,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      children: [
        if (isWalkIn)
          Column(
            children: [
              Icon(
                Icons.storefront,
                size: 80,
                color: AppTheme.primaryGreen.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                'Walk-in Customer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        else if (customer != null)
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                child: Text(
                  customer!.initials,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                customer!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (customer!.phone != null)
                Text(
                  customer!.phone!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPreviousBalance(BuildContext context) {
    if (customer == null || customer!.balance == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: customer!.isDebtor 
            ? AppTheme.alertRed.withValues(alpha: 0.1)
            : AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: customer!.isDebtor 
              ? AppTheme.alertRed.withValues(alpha: 0.3)
              : AppTheme.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Previous Balance:',
            style: TextStyle(
              color: customer!.isDebtor ? AppTheme.alertRed : AppTheme.primaryBlue,
              fontSize: 14,
            ),
          ),
          Text(
            '${customer!.isDebtor ? "-" : "+"}${FormatHelper.formatPrice(customer!.balance.abs(), symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol)}',
            style: TextStyle(
              color: customer!.isDebtor ? AppTheme.alertRed : AppTheme.primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context, CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Text(
            'Total to Pay',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            FormatHelper.formatPrice(cartProvider.total, symbol: Provider.of<CurrencyProvider>(context, listen: false).currencySymbol),
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${cartProvider.itemCount} Items • Order #TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayNow(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider,
    SalesProvider salesProvider,
    String paymentMethod,
  ) async {
    try {
      final saleId = await salesProvider.createSale(
        customerId: customer?.id ?? 'walk-in',
        customerName: customer?.name ?? 'Walk-in Customer',
        items: cartProvider.items,
        subtotal: cartProvider.subtotal,
        discount: cartProvider.discountAmount,
        discountType: 'fixed', // Always fixed now
        tax: 0.0, // No tax as per requirements
        taxRate: 0.0, // No tax as per requirements
        total: cartProvider.total,
        paymentMethod: paymentMethod,
        paymentStatus: paymentMethod == 'credit' ? 'pending' : 'paid',
        cashierId: authProvider.user?.uid ?? '',
        cashierName: authProvider.user?.name ?? 'User',
      );

      if (saleId != null && context.mounted) {
        // Navigate to receipt screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptScreen(
              saleId: saleId,
              customerName: customer?.name ?? 'Walk-in Customer',
              customerEmail: customer?.email,
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete sale: $e'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }
}
