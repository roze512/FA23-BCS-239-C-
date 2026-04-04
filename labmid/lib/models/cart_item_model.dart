/// Cart item model for POS system
class CartItemModel {
  final String productId;
  final String productName;
  final String? productImage;
  final double unitPrice;
  final double customPrice; // For runtime price change
  final int quantity;

  CartItemModel({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.unitPrice,
    double? customPrice,
    this.quantity = 1,
  }) : customPrice = customPrice ?? unitPrice;

  /// Calculate line total (custom price * quantity)
  double get lineTotal => customPrice * quantity;
  /// Alias getters for Firestore sync compatibility
  double get price => customPrice;
  double get total => lineTotal;

  /// Create CartItemModel from JSON/Map
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      customPrice: (json['customPrice'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  /// Convert CartItemModel to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'customPrice': customPrice,
      'quantity': quantity,
    };
  }

  /// Create a copy with updated fields
  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? unitPrice,
    double? customPrice,
    int? quantity,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      unitPrice: unitPrice ?? this.unitPrice,
      customPrice: customPrice ?? this.customPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(productId: $productId, productName: $productName, quantity: $quantity, lineTotal: $lineTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemModel && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}
