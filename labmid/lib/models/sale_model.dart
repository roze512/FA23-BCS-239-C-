import 'cart_item_model.dart';

/// Sale model for transactions
class SaleModel {
  final String id;
  final String? customerId;
  final String customerName;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final String? discountType; // 'percentage' or 'fixed'
  final double tax;
  final double taxRate;
  final double total;
  final String paymentMethod; // 'cash', 'card', 'credit'
  final String paymentStatus; // 'paid', 'pending'
  final String cashierId;
  final String cashierName;
  final DateTime createdAt;
  final int syncStatus;

  SaleModel({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.discountType,
    required this.tax,
    this.taxRate = 8.0,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = 'paid',
    required this.cashierId,
    required this.cashierName,
    DateTime? createdAt,
    this.syncStatus = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Generate invoice number from ID
  String get invoiceNumber => 'INV-${id.substring(0, 8).toUpperCase()}';

  /// Create SaleModel from JSON/Map
  factory SaleModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as String);
    // Parse items from JSON string
    final List<dynamic> itemsJsonList = _parseItems(itemsList);
    final items = itemsJsonList
        .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return SaleModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String,
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discountType'] as String?,
      tax: (json['tax'] as num).toDouble(),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 8.0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String? ?? 'paid',
      cashierId: json['cashierId'] as String,
      cashierName: json['cashierName'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  /// Parse items from JSON string
  static List<dynamic> _parseItems(String itemsStr) {
    // Simple JSON parsing for items stored as string
    try {
      // Remove brackets and split by items
      return []; // Simplified for now
    } catch (e) {
      return [];
    }
  }

  /// Convert SaleModel to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'items': _itemsToJsonString(),
      'subtotal': subtotal,
      'discount': discount,
      'discountType': discountType,
      'tax': tax,
      'taxRate': taxRate,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  /// Convert items list to JSON string for database storage
  String _itemsToJsonString() {
    final itemsJson = items.map((item) => item.toJson()).toList();
    return itemsJson.toString();
  }

  /// Create a copy with updated fields
  SaleModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<CartItemModel>? items,
    double? subtotal,
    double? discount,
    String? discountType,
    double? tax,
    double? taxRate,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? cashierId,
    String? cashierName,
    DateTime? createdAt,
    int? syncStatus,
  }) {
    return SaleModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      tax: tax ?? this.tax,
      taxRate: taxRate ?? this.taxRate,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'SaleModel(id: $id, total: $total, items: ${items.length}, customer: $customerName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
