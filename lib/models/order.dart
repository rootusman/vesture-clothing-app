class OrderItem {
  final String productId;
  final String productName;
  final String productBrand;
  final int quantity;
  final String size;
  final double price;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productBrand,
    required this.quantity,
    required this.size,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productBrand': productBrand,
    'quantity': quantity,
    'size': size,
    'price': price,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    productBrand: json['productBrand'] as String,
    quantity: (json['quantity'] as num).toInt(),
    size: json['size'] as String? ?? '',
    price: (json['price'] as num).toDouble(),
  );
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final double shippingCost;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final DateTime createdAt;
  final String shippingAddress;
  final String? paymentMethod;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.shippingCost,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'items': items.map((item) => item.toJson()).toList(),
    'totalAmount': totalAmount,
    'shippingCost': shippingCost,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'shippingAddress': shippingAddress,
    'paymentMethod': paymentMethod,
  };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? itemsJson = json['items'] as List<dynamic>?;
    final List<OrderItem> items = itemsJson != null
        ? itemsJson
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
        : <OrderItem>[];

    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: items,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      shippingAddress: json['shippingAddress'] as String,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    double? shippingCost,
    String? status,
    DateTime? createdAt,
    String? shippingAddress,
    String? paymentMethod,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
