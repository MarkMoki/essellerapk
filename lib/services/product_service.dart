import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    final response = await _supabase.from('products').select();
    return response.map((json) => Product.fromJson(json)).toList();
  }

  Future<void> addProduct(Product product) async {
    await _supabase.from('products').insert(product.toJson());
  }

  Future<void> updateProduct(Product product) async {
    await _supabase.from('products').update(product.toJson()).eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }
}