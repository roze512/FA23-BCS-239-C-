/// Stock movement model for tracking inventory changes
class StockMovementModel {
  final String id;
  final String productId;
  final String type; // 'in' or 'out'
  final int quantity;
  final String? reason;
  final String? supplier;
  final String? reference;
  final String? notes;
  final int previousStock;
  final int newStock;
  final DateTime createdAt;
  final int syncStatus;

  StockMovementModel({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.reason,
    this.supplier,
    this.reference,
    this.notes,
    required this.previousStock,
    required this.newStock,
    required this.createdAt,
    this.syncStatus = 0,
  });

  /// Create StockMovementModel from JSON/Map
  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      reason: json['reason'] as String?,
      supplier: json['supplier'] as String?,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      previousStock: json['previousStock'] as int,
      newStock: json['newStock'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  /// Convert StockMovementModel to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'supplier': supplier,
      'reference': reference,
      'notes': notes,
      'previousStock': previousStock,
      'newStock': newStock,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  /// Create a copy with updated fields
  StockMovementModel copyWith({
    String? id,
    String? productId,
    String? type,
    int? quantity,
    String? reason,
    String? supplier,
    String? reference,
    String? notes,
    int? previousStock,
    int? newStock,
    DateTime? createdAt,
    int? syncStatus,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      supplier: supplier ?? this.supplier,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'StockMovementModel(id: $id, productId: $productId, type: $type, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockMovementModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
