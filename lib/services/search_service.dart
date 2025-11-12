import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class SearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? sortBy, // 'price_asc', 'price_desc', 'rating', 'newest'
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .gt('stock', 0)
          .range(offset, offset + limit - 1);

      // Note: Additional filters would be applied here in a real implementation
      // For now, we'll keep it simple with just the search query

      // Add sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'price_asc':
            queryBuilder = queryBuilder.order('price', ascending: true);
            break;
          case 'price_desc':
            queryBuilder = queryBuilder.order('price', ascending: false);
            break;
          case 'rating':
            // This would require a join with review stats, simplified for now
            queryBuilder = queryBuilder.order('created_at', ascending: false);
            break;
          case 'newest':
          default:
            queryBuilder = queryBuilder.order('created_at', ascending: false);
            break;
        }
      } else {
        queryBuilder = queryBuilder.order('created_at', ascending: false);
      }

      final response = await queryBuilder;
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from('products')
          .select('name')
          .ilike('name', '$query%')
          .limit(10);

      return response.map((item) => item['name'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get search suggestions: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('products')
          .select('category')
          .not('category', 'is', null);

      final categories = response
          .map((item) => item['category'] as String?)
          .where((category) => category != null && category.isNotEmpty)
          .toSet()
          .toList();

      return categories.cast<String>();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_featured', true)
          .eq('stock', '>0')
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get featured products: $e');
    }
  }

  Future<List<Product>> getProductsByCategory(String category, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category', category)
          .eq('stock', '>0')
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  Future<Map<String, dynamic>> getSearchFilters() async {
    try {
      // Get min and max prices
      final priceResponse = await _supabase
          .from('products')
          .select('price')
          .order('price', ascending: true);

      final prices = priceResponse.map((item) => item['price'] as double).toList();

      double? minPrice;
      double? maxPrice;
      if (prices.isNotEmpty) {
        minPrice = prices.first;
        maxPrice = prices.last;
      }

      final categories = await getCategories();

      return {
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'categories': categories,
      };
    } catch (e) {
      throw Exception('Failed to get search filters: $e');
    }
  }
}