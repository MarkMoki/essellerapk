import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReturnsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUserReturnRequests(String userId, {String? status}) async {
    try {
      final response = await _supabase
          .from('return_requests')
          .select('*, orders(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch return requests: $e');
    }
  }

  Future<Map<String, dynamic>> createReturnRequest({
    required String userId,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    required String description,
    List<String>? images,
  }) async {
    try {
      // Validate that the order belongs to the user and is eligible for return
      final orderResponse = await _supabase
          .from('orders')
          .select('status, created_at')
          .eq('id', orderId)
          .eq('user_id', userId)
          .single();

      final orderStatus = orderResponse['status'];
      final orderDate = DateTime.parse(orderResponse['created_at']);
      final daysSinceOrder = DateTime.now().difference(orderDate).inDays;

      // Check if order is eligible for return (delivered and within 30 days)
      if (orderStatus != 'delivered') {
        throw Exception('Only delivered orders can be returned');
      }

      if (daysSinceOrder > 30) {
        throw Exception('Returns must be requested within 30 days of delivery');
      }

      // Calculate refund amount
      double refundAmount = 0;
      for (final item in items) {
        final productId = item['product_id'];
        final quantity = item['quantity'];

        // Get product price from order items
        final orderItemResponse = await _supabase
            .from('order_items')
            .select('price')
            .eq('order_id', orderId)
            .eq('product_id', productId)
            .single();

        refundAmount += (orderItemResponse['price'] as num).toDouble() * quantity;
      }

      // Create return request
      final returnRequest = {
        'user_id': userId,
        'order_id': orderId,
        'items': items,
        'reason': reason,
        'description': description,
        'images': images ?? [],
        'refund_amount': refundAmount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('return_requests')
          .insert(returnRequest)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create return request: $e');
    }
  }

  Future<void> updateReturnStatus(String returnId, String newStatus, {String? adminNotes}) async {
    try {
      final updateData = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      await _supabase
          .from('return_requests')
          .update(updateData)
          .eq('id', returnId);

      // If approved, create refund record
      if (newStatus == 'approved') {
        await _createRefundRecord(returnId);
      }
    } catch (e) {
      throw Exception('Failed to update return status: $e');
    }
  }

  Future<void> _createRefundRecord(String returnId) async {
    try {
      // Get return request details
      final returnRequest = await _supabase
          .from('return_requests')
          .select('user_id, order_id, refund_amount')
          .eq('id', returnId)
          .single();

      // Create refund record
      await _supabase.from('refunds').insert({
        'return_id': returnId,
        'user_id': returnRequest['user_id'],
        'order_id': returnRequest['order_id'],
        'amount': returnRequest['refund_amount'],
        'status': 'processing',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to create refund record: $e');
    }
  }

  Future<void> processRefund(String refundId, {String? transactionId}) async {
    try {
      final updateData = {
        'status': 'completed',
        'processed_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      await _supabase
          .from('refunds')
          .update(updateData)
          .eq('id', refundId);
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllReturnRequests({String? status, int limit = 50}) async {
    try {
      final response = await _supabase
          .from('return_requests')
          .select('*, orders(*), users(email, first_name, last_name)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch return requests: $e');
    }
  }

  Future<Map<String, dynamic>> getReturnStats() async {
    try {
      final response = await _supabase
          .from('return_requests')
          .select('status');

      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int completed = 0;

      for (final request in response) {
        switch (request['status']) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'completed':
            completed++;
            break;
        }
      }

      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'completed': completed,
        'total': response.length,
      };
    } catch (e) {
      throw Exception('Failed to get return stats: $e');
    }
  }

  Future<bool> canReturnOrder(String userId, String orderId) async {
    try {
      final orderResponse = await _supabase
          .from('orders')
          .select('status, created_at')
          .eq('id', orderId)
          .eq('user_id', userId)
          .single();

      final orderStatus = orderResponse['status'];
      final orderDate = DateTime.parse(orderResponse['created_at']);
      final daysSinceOrder = DateTime.now().difference(orderDate).inDays;

      // Check if order is eligible for return
      return orderStatus == 'delivered' && daysSinceOrder <= 30;
    } catch (e) {
      return false;
    }
  }
}