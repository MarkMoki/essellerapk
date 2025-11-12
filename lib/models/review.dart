class Review {
  final String id;
  final String userId;
  final String productId;
  final String? orderId;
  final int rating; // 1-5 stars
  final String? title;
  final String comment;
  final List<String>? images;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    this.orderId,
    required this.rating,
    this.title,
    required this.comment,
    this.images,
    this.isVerifiedPurchase = false,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasImages => images != null && images!.isNotEmpty;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      orderId: json['order_id'],
      rating: json['rating'],
      title: json['title'],
      comment: json['comment'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'order_id': orderId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'is_verified_purchase': isVerifiedPurchase,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Review copyWith({
    String? title,
    String? comment,
    List<String>? images,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id,
      userId: userId,
      productId: productId,
      orderId: orderId,
      rating: rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      isVerifiedPurchase: isVerifiedPurchase,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProductReviewStats {
  final String productId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 stars count
  final int verifiedPurchaseCount;

  ProductReviewStats({
    required this.productId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedPurchaseCount,
  });

  factory ProductReviewStats.fromJson(Map<String, dynamic> json) {
    return ProductReviewStats(
      productId: json['product_id'],
      averageRating: (json['average_rating'] as num).toDouble(),
      totalReviews: json['total_reviews'],
      ratingDistribution: Map<int, int>.from(json['rating_distribution']),
      verifiedPurchaseCount: json['verified_purchase_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'rating_distribution': ratingDistribution,
      'verified_purchase_count': verifiedPurchaseCount,
    };
  }

  int getRatingCount(int stars) {
    return ratingDistribution[stars] ?? 0;
  }

  double getRatingPercentage(int stars) {
    if (totalReviews == 0) return 0.0;
    return (getRatingCount(stars) / totalReviews) * 100;
  }
}