import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist.dart';

class WishlistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Wishlist> getWishlist(String userId) async {
    try {
      final response = await _supabase
          .from('wishlist_items')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      final items = response.map((json) => WishlistItem.fromJson(json)).toList();

      return Wishlist(
        userId: userId,
        items: items,
        lastUpdated: items.isNotEmpty ? items.first.addedAt : DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to fetch wishlist: $e');
    }
  }

  Future<void> addToWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      // Check if item already exists
      final existing = await _supabase
          .from('wishlist_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Product already in wishlist');
      }

      await _supabase.from('wishlist_items').insert({
        'user_id': userId,
        'product_id': productId,
        'added_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      await _supabase
          .from('wishlist_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }

  Future<bool> isInWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final response = await _supabase
          .from('wishlist_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check wishlist status: $e');
    }
  }

  Future<void> clearWishlist(String userId) async {
    try {
      await _supabase
          .from('wishlist_items')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear wishlist: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWishlistWithProducts(String userId) async {
    try {
      final response = await _supabase
          .from('wishlist_items')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to fetch wishlist with products: $e');
    }
  }

  Future<void> moveWishlistItem({
    required String userId,
    required String fromProductId,
    required String toProductId,
  }) async {
    try {
      // This would require updating the order/position field if implemented
      // For now, just update the added_at timestamp to reorder
      await _supabase
          .from('wishlist_items')
          .update({'added_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('product_id', fromProductId);
    } catch (e) {
      throw Exception('Failed to move wishlist item: $e');
    }
  }

  Future<Map<String, dynamic>> getWishlistStats(String userId) async {
    try {
      final wishlist = await getWishlist(userId);
      final wishlistWithProducts = await getWishlistWithProducts(userId);

      double totalValue = 0;
      final categories = <String, int>{};

      for (final item in wishlistWithProducts) {
        final product = item['products'];
        if (product != null) {
          totalValue += (product['price'] as num).toDouble();

          // Assuming products have a category field
          final category = product['category'] as String?;
          if (category != null) {
            categories[category] = (categories[category] ?? 0) + 1;
          }
        }
      }

      return {
        'total_items': wishlist.itemCount,
        'total_value': totalValue,
        'categories': categories,
        'last_updated': wishlist.lastUpdated.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get wishlist stats: $e');
    }
  }

  Future<List<String>> getPopularWishlistProducts({int limit = 10}) async {
    try {
      // This would typically use a more complex query with aggregations
      // For now, return a simple implementation
      final response = await _supabase
          .from('wishlist_items')
          .select('product_id')
          .limit(limit * 5); // Get more to account for duplicates

      final productCounts = <String, int>{};
      for (final item in response) {
        final productId = item['product_id'] as String;
        productCounts[productId] = (productCounts[productId] ?? 0) + 1;
      }

      final sortedProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedProducts.take(limit).map((e) => e.key).toList();
    } catch (e) {
      throw Exception('Failed to get popular wishlist products: $e');
    }
  }

  Future<void> shareWishlist({
    required String userId,
    required String shareToken,
    required List<String> productIds,
  }) async {
    try {
      await _supabase.from('wishlist_shares').insert({
        'user_id': userId,
        'share_token': shareToken,
        'product_ids': productIds,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to share wishlist: $e');
    }
  }

  Future<List<String>?> getSharedWishlist(String shareToken) async {
    try {
      final response = await _supabase
          .from('wishlist_shares')
          .select('product_ids, expires_at')
          .eq('share_token', shareToken)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response == null) return null;

      return List<String>.from(response['product_ids']);
    } catch (e) {
      throw Exception('Failed to get shared wishlist: $e');
    }
  }
}