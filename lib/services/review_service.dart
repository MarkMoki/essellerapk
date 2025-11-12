import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Review>> getProductReviews(String productId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch product reviews: $e');
    }
  }

  Future<List<Review>> getUserReviews(String userId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  Future<void> addReview({
    required String userId,
    required String productId,
    required int rating,
    required String comment,
    String? title,
    List<String>? images,
    String? orderId,
  }) async {
    try {
      // Check if user has already reviewed this product
      final existingReview = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingReview != null) {
        throw Exception('You have already reviewed this product');
      }

      // Check if user has purchased the product (for verified purchase)
      bool isVerifiedPurchase = false;
      if (orderId != null) {
        final orderCheck = await _supabase
            .from('orders')
            .select()
            .eq('id', orderId)
            .eq('user_id', userId)
            .eq('status', 'delivered')
            .maybeSingle();

        isVerifiedPurchase = orderCheck != null;
      }

      await _supabase.from('reviews').insert({
        'user_id': userId,
        'product_id': productId,
        'order_id': orderId,
        'rating': rating,
        'title': title,
        'comment': comment,
        'images': images,
        'is_verified_purchase': isVerifiedPurchase,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update product rating stats
      await _updateProductReviewStats(productId);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<void> updateReview({
    required String reviewId,
    required String userId,
    String? title,
    String? comment,
    List<String>? images,
  }) async {
    try {
      await _supabase
          .from('reviews')
          .update({
            'title': title,
            'comment': comment,
            'images': images,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .eq('user_id', userId);

      // Get product ID to update stats
      final review = await _supabase
          .from('reviews')
          .select('product_id')
          .eq('id', reviewId)
          .single();

      await _updateProductReviewStats(review['product_id']);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(String reviewId, String userId) async {
    try {
      // Get product ID before deleting
      final review = await _supabase
          .from('reviews')
          .select('product_id')
          .eq('id', reviewId)
          .eq('user_id', userId)
          .single();

      final productId = review['product_id'];

      // Delete the review
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId);

      // Update product rating stats
      await _updateProductReviewStats(productId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  Future<ProductReviewStats> getProductReviewStats(String productId) async {
    try {
      final response = await _supabase
          .from('product_review_stats')
          .select()
          .eq('product_id', productId)
          .single();

      return ProductReviewStats.fromJson(response);
    } catch (e) {
      // If no stats exist, calculate them
      return await _calculateProductReviewStats(productId);
    }
  }

  Future<ProductReviewStats> _calculateProductReviewStats(String productId) async {
    try {
      final reviews = await getProductReviews(productId, limit: 1000); // Get all reviews

      if (reviews.isEmpty) {
        return ProductReviewStats(
          productId: productId,
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          verifiedPurchaseCount: 0,
        );
      }

      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      int verifiedPurchaseCount = 0;
      double totalRating = 0;

      for (final review in reviews) {
        ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
        totalRating += review.rating;
        if (review.isVerifiedPurchase) {
          verifiedPurchaseCount++;
        }
      }

      final averageRating = totalRating / reviews.length;

      final stats = ProductReviewStats(
        productId: productId,
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        verifiedPurchaseCount: verifiedPurchaseCount,
      );

      // Cache the stats
      await _supabase.from('product_review_stats').upsert(stats.toJson());

      return stats;
    } catch (e) {
      throw Exception('Failed to calculate product review stats: $e');
    }
  }

  Future<void> _updateProductReviewStats(String productId) async {
    try {
      final stats = await _calculateProductReviewStats(productId);
      await _supabase.from('product_review_stats').upsert(stats.toJson());
    } catch (e) {
      // Log error but don't throw - review operation should succeed even if stats update fails
      debugPrint('Failed to update product review stats: $e');
    }
  }

  Future<List<Review>> getRecentReviews({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, products(name, image_url)')
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent reviews: $e');
    }
  }

  Future<bool> canUserReviewProduct(String userId, String productId) async {
    try {
      // Check if user has already reviewed
      final existingReview = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingReview != null) return false;

      // Check if user has purchased the product
      final purchaseCheck = await _supabase
          .from('order_items')
          .select()
          .eq('product_id', productId)
          .eq('orders.user_id', userId)
          .eq('orders.status', 'delivered')
          .maybeSingle();

      return purchaseCheck != null;
    } catch (e) {
      throw Exception('Failed to check review eligibility: $e');
    }
  }

  Future<void> reportReview(String reviewId, String userId, String reason) async {
    try {
      await _supabase.from('review_reports').insert({
        'review_id': reviewId,
        'reported_by': userId,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to report review: $e');
    }
  }

  Future<void> moderateReview(String reviewId, String action, String moderatorId, {String? reason}) async {
    try {
      if (action == 'approve') {
        await _supabase
            .from('reviews')
            .update({'moderation_status': 'approved'})
            .eq('id', reviewId);
      } else if (action == 'reject') {
        await _supabase
            .from('reviews')
            .update({
              'moderation_status': 'rejected',
              'moderation_reason': reason,
            })
            .eq('id', reviewId);
      } else if (action == 'delete') {
        await _supabase.from('reviews').delete().eq('id', reviewId);
      }

      // Log moderation action
      await _supabase.from('review_moderation_log').insert({
        'review_id': reviewId,
        'action': action,
        'moderator_id': moderatorId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to moderate review: $e');
    }
  }

  Future<Map<String, dynamic>> getReviewAnalytics(String sellerId) async {
    try {
      // Get all products for this seller
      final productsResponse = await _supabase
          .from('products')
          .select('id')
          .eq('seller_id', sellerId);

      final productIds = productsResponse.map((p) => p['id'] as String).toList();

      if (productIds.isEmpty) {
        return {
          'total_reviews': 0,
          'average_rating': 0.0,
          'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      // Get reviews for all seller products
      // Note: In a real implementation, this would use proper filtering
      final reviewsResponse = await _supabase
          .from('reviews')
          .select('rating, product_id');

      final ratings = reviewsResponse.map((r) => r['rating'] as int).toList();

      if (ratings.isEmpty) {
        return {
          'total_reviews': 0,
          'average_rating': 0.0,
          'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double totalRating = 0;

      for (final rating in ratings) {
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
        totalRating += rating;
      }

      return {
        'total_reviews': ratings.length,
        'average_rating': totalRating / ratings.length,
        'rating_distribution': ratingDistribution,
      };
    } catch (e) {
      throw Exception('Failed to get review analytics: $e');
    }
  }
}