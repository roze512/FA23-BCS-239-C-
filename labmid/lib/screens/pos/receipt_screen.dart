import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';
import '../../utils/format_helper.dart';

/// Receipt screen with SMS/WhatsApp/Email functionality
class ReceiptScreen extends StatefulWidget {
  final String saleId;
  final String customerName;
  final String? customerEmail;

  const ReceiptScreen({
    super.key,
    required this.saleId,
    required this.customerName,
    this.customerEmail,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  CustomerModel? _customer;
  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    await salesProvider.getSaleById(widget.saleId);
    
    // Try to load full customer details if we have customer ID from sale
    final sale = salesProvider.currentSale;
    if (sale?.customerId != null) {
      try {
        _customer = await _customerService.getCustomerById(sale!.customerId!);
        setState(() {});
      } catch (e) {
        // Customer not found, that's okay
      }
    }
  }

  // Generate receipt message
  String _generateReceiptMessage() {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final sale = salesProvider.currentSale;
    if (sale == null) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('🧾 PAYMENT RECEIPT');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Invoice: ${sale.invoiceNumber}');
    buffer.writeln('Date: ${_formatDate(sale.createdAt)}');
    buffer.writeln('Customer: ${widget.customerName}');
    buffer.writeln('');
    buffer.writeln('ITEMS:');
    
    for (final item in sale.items) {
      buffer.writeln('• ${item.productName} x${item.quantity}');
      buffer.writeln('  ${FormatHelper.formatMoney(item.lineTotal)}');
    }
    
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Subtotal: ${FormatHelper.formatMoney(sale.subtotal)}');
    if (sale.discount > 0) {
      buffer.writeln('Discount: -${FormatHelper.formatMoney(sale.discount)}');
    }
    buffer.writeln('Tax: ${FormatHelper.formatMoney(sale.tax)}');
    buffer.writeln('TOTAL: ${FormatHelper.formatMoney(sale.total)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('Thank you for your purchase!');
    buffer.writeln('SmartPOS');
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 📩 SEND SMS
  // 📩 SEND SMS
  Future<void> _sendSMS(BuildContext context) async {
    final phone = _customer?.phone ?? '';
    if (phone.isEmpty) {
      _showError(context, 'Customer phone number not available');
      return;
    }

    try {
      final message = _generateReceiptMessage();
      final uri = Uri.parse('sms:$phone?body=${Uri. encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError(context, 'Could not open SMS app');
      }
    } catch (e) {
      _showError(context, 'Could not send SMS');
    }
  }

  // 💬 SEND WHATSAPP
  Future<void> _sendWhatsApp(BuildContext context) async {
    final phone = _customer?.phone ?? '';
    if (phone.isEmpty) {
      _showError(context, 'Customer phone number not available');
      return;
    }

    // Clean phone number
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Add country code if not present
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+92${cleanPhone.substring(1)}';
      } else {
        cleanPhone = '+92$cleanPhone';
      }
    }

    final message = Uri.encodeComponent(_generateReceiptMessage());
    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$message';
    
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'WhatsApp not installed');
    }
  }

  // 📧 SEND EMAIL
  Future<void> _sendEmail(BuildContext context) async {
    final email = widget.customerEmail ?? _customer?.email ?? '';
    if (email.isEmpty) {
      _showError(context, 'Customer email not available');
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError(context, 'Invalid customer email');
      return;
    }

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final sale = salesProvider.currentSale;
    final subject = Uri.encodeComponent('Payment Receipt – Invoice ${sale?.invoiceNumber ?? ""}');
    final body = Uri.encodeComponent(_generateReceiptMessage());
    
    final emailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showError(context, 'Could not open email app');
    }
  }

  void _showSuccess(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: const Color(0xFF00E676),
      textColor: Colors.black,
    );
  }

  void _showError(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        automaticallyImplyLeading: false,
        title: const Text('Receipt', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Consumer2<SalesProvider, AuthProvider>(
        builder: (context, salesProvider, authProvider, child) {
          final sale = salesProvider.currentSale;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Success Animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppTheme.primaryGreen,
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Receipt Content
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Name
                      Center(
                        child: Text(
                          authProvider.user?.name ?? 'Smart POS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Paid Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PAID',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Divider(color: AppTheme.borderDark, height: 32),

                      // Invoice Details
                      _buildDetailRow('Invoice No.', sale?.invoiceNumber ?? widget.saleId.substring(0, 8).toUpperCase()),
                      _buildDetailRow('Date', _formatDate(sale?.createdAt ?? DateTime.now())),
                      _buildDetailRow('Customer', widget.customerName),
                      _buildDetailRow('Cashier', authProvider.user?.name ?? 'User'),
                      const Divider(color: AppTheme.borderDark, height: 32),

                      // Items
                      const Text(
                        'Items',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (sale != null)
                        ...sale.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.productName}',
                                      style: const TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ),
                                  Text(
                                    FormatHelper.formatMoney(item.lineTotal),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            )),
                      const Divider(color: AppTheme.borderDark, height: 32),

                      // Totals
                      if (sale != null) ...[
                        _buildDetailRow('Subtotal', FormatHelper.formatMoney(sale.subtotal)),
                        if (sale.discount > 0)
                          _buildDetailRow('Discount', '-${FormatHelper.formatMoney(sale.discount)}', isHighlight: true),
                        _buildDetailRow('Tax (${sale.taxRate.toStringAsFixed(0)}%)', FormatHelper.formatMoney(sale.tax)),
                        const Divider(color: AppTheme.borderDark, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              FormatHelper.formatMoney(sale.total),
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Send Receipt Section
                const Text(
                  'Send Receipt to Customer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // 📩 SMS Button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.sms,
                        label: 'SMS',
                        color: const Color(0xFF4CAF50),
                        onTap: () => _sendSMS(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // 💬 WhatsApp Button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _sendWhatsApp(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // 📧 Email Button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.email,
                        label: 'Email',
                        color: const Color(0xFF2196F3),
                        onTap: () => _sendEmail(context),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false).clearCart();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppTheme.alertRed : AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppTheme.alertRed : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
