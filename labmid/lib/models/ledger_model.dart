/// Ledger model for customer account tracking
class LedgerModel {
  final String id;
  final String customerId;
  final String type; // 'sale', 'payment', 'adjustment'
  final double amount;
  final String description;
  final double balanceBefore;
  final double balanceAfter;
  final String? saleId;
  final DateTime createdAt;

  LedgerModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceBefore,
    required this.balanceAfter,
    this.saleId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create LedgerModel from JSON/Map
  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      balanceBefore: (json['balanceBefore'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      saleId: json['saleId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert LedgerModel to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'type': type,
      'amount': amount,
      'description': description,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'saleId': saleId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  LedgerModel copyWith({
    String? id,
    String? customerId,
    String? type,
    double? amount,
    String? description,
    double? balanceBefore,
    double? balanceAfter,
    String? saleId,
    DateTime? createdAt,
  }) {
    return LedgerModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      saleId: saleId ?? this.saleId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'LedgerModel(id: $id, customerId: $customerId, type: $type, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LedgerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
