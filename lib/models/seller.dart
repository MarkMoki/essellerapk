class Seller {
  final String id;
  final String createdBy;
  final DateTime expiresAt;
  final DateTime createdAt;

  Seller({
    required this.id,
    required this.createdBy,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'],
      createdBy: json['created_by'],
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get timeUntilExpiration => expiresAt.difference(DateTime.now());
}