class ShippingSettings {
  final bool isFreeShipping;
  final double shippingCost;

  const ShippingSettings({
    required this.isFreeShipping,
    required this.shippingCost,
  });

  // Default settings: free shipping
  factory ShippingSettings.defaultSettings() {
    return const ShippingSettings(isFreeShipping: true, shippingCost: 0.0);
  }

  Map<String, dynamic> toJson() => {
    'isFreeShipping': isFreeShipping,
    'shippingCost': shippingCost,
  };

  factory ShippingSettings.fromJson(Map<String, dynamic> json) {
    return ShippingSettings(
      isFreeShipping: json['isFreeShipping'] as bool? ?? true,
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ShippingSettings copyWith({bool? isFreeShipping, double? shippingCost}) {
    return ShippingSettings(
      isFreeShipping: isFreeShipping ?? this.isFreeShipping,
      shippingCost: shippingCost ?? this.shippingCost,
    );
  }

  double get effectiveCost => isFreeShipping ? 0.0 : shippingCost;
}
