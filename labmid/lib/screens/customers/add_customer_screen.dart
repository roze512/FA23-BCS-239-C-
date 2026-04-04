import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import '../../config/theme.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';

/// Screen for adding a new customer
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isSaving = false;
  String _countryCode = '+92';

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
      final customer = CustomerModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: '$_countryCode ${_phoneController.text.trim()}',
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        dateOfBirth: _dateOfBirth?.toIso8601String(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Provider.of<CustomerProvider>(context, listen: false).addCustomer(customer);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Customer added successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to add customer: $e',
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
        title: const Text('Add Customer', style: TextStyle(color: Colors.white)),
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Name too short';
                if (v.trim().length > 50) return 'Name too long (max 50)';
                if (RegExp(r'[0-9]').hasMatch(v)) return 'Name should not contain numbers';
                return null;
              },
              maxLength: 50,
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
                    : const Text('Save Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
