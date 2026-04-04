import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import '../../config/theme.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';

/// Screen for editing an existing customer
class EditCustomerScreen extends StatefulWidget {
  final CustomerModel customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  DateTime? _dateOfBirth;
  bool _isSaving = false;
  String _countryCode = '+92';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    
    // Parse phone and country code
    String phone = widget.customer.phone ?? '';
    if (phone.contains(' ')) {
      final parts = phone.split(' ');
      if (['+92', '+91', '+1', '+44', '+971'].contains(parts[0])) {
        _countryCode = parts[0];
        phone = parts.sublist(1).join(' ');
      }
    } else {
      // Find matching prefix if no space
      for (var code in ['+92', '+91', '+1', '+44', '+971']) {
        if (phone.startsWith(code)) {
          _countryCode = code;
          phone = phone.substring(code.length);
          break;
        }
      }
    }
    
    _phoneController = TextEditingController(text: phone);
    _emailController = TextEditingController(text: widget.customer.email ?? '');
    _addressController = TextEditingController(text: widget.customer.address ?? '');
    _cityController = TextEditingController(text: widget.customer.city ?? '');
    _pincodeController = TextEditingController(text: widget.customer.pincode ?? '');
    
    if (widget.customer.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(widget.customer.dateOfBirth!);
    }
    
    _isActive = widget.customer.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedCustomer = widget.customer.copyWith(
        name: _nameController.text.trim(),
        phone: '$_countryCode ${_phoneController.text.trim()}',
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        dateOfBirth: _dateOfBirth?.toIso8601String(),
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );

      await Provider.of<CustomerProvider>(context, listen: false).updateCustomer(updatedCustomer);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Customer updated successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to update customer: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getNameInitials() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: const Text('Edit Customer', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _isActive ? Icons.toggle_on : Icons.toggle_off,
              color: _isActive ? AppTheme.primaryGreen : Colors.grey,
              size: 32,
            ),
            onPressed: () {
              setState(() {
                _isActive = !_isActive;
              });
            },
            tooltip: _isActive ? 'Active Status: ON' : 'Active Status: OFF',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                child: Text(
                  _getNameInitials(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Customer Name
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter customer name',
                prefixIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
              ),
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Name is required';
                if (value.trim().length < 2) return 'Name is too short';
                if (RegExp(r'[0-9]').hasMatch(value)) return 'Name should not contain numbers';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    value: _countryCode,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Code'),
                    items: ['+92', '+91', '+1', '+44', '+971']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _countryCode = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: '3001234567',
                      prefixIcon: Icon(Icons.phone, color: AppTheme.primaryGreen),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Phone is required';
                      final cleanPhone = value.trim();
                      if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) return 'Only digits allowed';
                      if (cleanPhone.length < 7 || cleanPhone.length > 15) return 'Invalid length (7-15 digits)';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email Address
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address (Optional)',
                hintText: 'customer@example.com',
                prefixIcon: Icon(Icons.email, color: AppTheme.primaryGreen),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !EmailValidator.validate(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.home, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
               height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                 child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Update Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
