class WishlistItem {
  final String id;
  final String userId;
  final String productId;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'added_at': addedAt.toIso8601String(),
    };
  }
}

class Wishlist {
  final String userId;
  final List<WishlistItem> items;
  final DateTime lastUpdated;

  Wishlist({
    required this.userId,
    required this.items,
    required this.lastUpdated,
  });

  int get itemCount => items.length;

  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  WishlistItem? getItem(String productId) {
    for (var item in items) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      userId: json['user_id'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => WishlistItem.fromJson(item))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  Wishlist copyWith({
    List<WishlistItem>? items,
    DateTime? lastUpdated,
  }) {
    return Wishlist(
      userId: userId,
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}