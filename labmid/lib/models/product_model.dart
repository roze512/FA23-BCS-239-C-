/// Product model for inventory management
class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final int quantity;
  final int minStock;
  final String unitType;
  final String? categoryId;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    required this.price,
    this.costPrice,
    required this.quantity,
    this.minStock = 10,
    this.unitType = 'item',
    this.categoryId,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  /// Calculate profit margin
  double get profitMargin {
    if (costPrice != null && costPrice! > 0) {
      return ((price - costPrice!) / price * 100);
    }
    return 0;
  }

  /// Check if low stock
  bool get isLowStock => quantity <= minStock;

  /// Create ProductModel from JSON/Map
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: (json['price'] as num).toDouble(),
      costPrice: json['costPrice'] != null ? (json['costPrice'] as num).toDouble() : null,
      quantity: json['quantity'] as int,
      minStock: json['minStock'] as int? ?? 10,
      unitType: json['unitType'] as String? ?? 'item',
      categoryId: json['categoryId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  /// Convert ProductModel to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'costPrice': costPrice,
      'quantity': quantity,
      'minStock': minStock,
      'unitType': unitType,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    double? price,
    double? costPrice,
    int? quantity,
    int? minStock,
    String? unitType,
    String? categoryId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      unitType: unitType ?? this.unitType,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
