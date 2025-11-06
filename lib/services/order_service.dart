import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createOrder(Order order) async {
    await _supabase.from('orders').insert({
      'id': order.id,
      'user_id': order.userId,
      'items': order.items.map((item) => item.toJson()).toList(),
      'total_amount': order.totalAmount,
      'status': order.status,
      'created_at': order.createdAt.toIso8601String(),
    });
  }

  Future<List<Order>> fetchUserOrders(String userId) async {
    final response = await _supabase.from('orders').select().eq('user_id', userId);
    return response.map((json) => Order.fromJson(json)).toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase.from('orders').update({'status': status}).eq('id', orderId);
  }
}