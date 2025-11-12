import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _supabase.from('products').select();
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> addProduct(Product product, AuthProvider authProvider) async {
    try {
      // Check if seller is active (not expired)
      if (authProvider.isSeller) {
        final isActive = await authProvider.isSellerActive;
        if (!isActive) {
          throw Exception('Seller account is expired. Please contact admin to renew your account.');
        }
      }

      final productData = product.toJson();
      if (authProvider.isSeller) {
        productData['seller_id'] = authProvider.user!.id;
      }
      await _supabase.from('products').insert(productData);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product, AuthProvider authProvider) async {
    try {
      // Check if seller is active (not expired)
      if (authProvider.isSeller) {
        final isActive = await authProvider.isSellerActive;
        if (!isActive) {
          throw Exception('Seller account is expired. Please contact admin to renew your account.');
        }
      }

      final productData = product.toJson();
      if (authProvider.isSeller) {
        productData['seller_id'] = authProvider.user!.id;
      }
      await _supabase.from('products').update(productData).eq('id', product.id);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id, AuthProvider authProvider) async {
    try {
      // Check if seller is active (not expired)
      if (authProvider.isSeller) {
        final isActive = await authProvider.isSellerActive;
        if (!isActive) {
          throw Exception('Seller account is expired. Please contact admin to renew your account.');
        }

        // Sellers can only delete their own products
        await _supabase
            .from('products')
            .delete()
            .eq('id', id)
            .eq('seller_id', authProvider.user!.id);
      } else {
        // Admins can delete any product
        await _supabase.from('products').delete().eq('id', id);
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<List<Product>> fetchSellerProducts(String sellerId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', sellerId);
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch seller products: $e');
    }
  }
}