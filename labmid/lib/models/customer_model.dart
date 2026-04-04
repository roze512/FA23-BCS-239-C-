/// Customer model for customer management
class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? pincode;
  final String? dateOfBirth;
  final String? photoUrl;
  final double balance; // Negative = they owe us, Positive = we owe them
  final bool isActive; // Active/Inactive status
  final DateTime? lastPurchaseAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.pincode,
    this.dateOfBirth,
    this.photoUrl,
    this.balance = 0.0,
    this.isActive = true, // Default active
    this.lastPurchaseAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if customer owes us money
  bool get isDebtor => balance < 0;

  /// Check if customer has prepaid/credit balance
  bool get hasCredit => balance > 0;

  /// Check if customer recently made a purchase (in last 30 days)
  bool get hasRecentPurchase =>
      lastPurchaseAt != null &&
      DateTime.now().difference(lastPurchaseAt!).inDays <= 30;

  /// Get initials from name for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Create CustomerModel from JSON/Map
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      photoUrl: json['photoUrl'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] == 1 || json['isActive'] == true, // SQLite boolean or direct bool
      lastPurchaseAt: json['lastPurchaseAt'] != null
          ? DateTime.parse(json['lastPurchaseAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert CustomerModel to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'pincode': pincode,
      'dateOfBirth': dateOfBirth,
      'photoUrl': photoUrl,
      'balance': balance,
      'isActive': isActive ? 1 : 0, // SQLite boolean
      'lastPurchaseAt': lastPurchaseAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? pincode,
    String? dateOfBirth,
    String? photoUrl,
    double? balance,
    bool? isActive,
    DateTime? lastPurchaseAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: photoUrl ?? this.photoUrl,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
