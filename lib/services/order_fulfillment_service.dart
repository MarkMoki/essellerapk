import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderFulfillmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> updateOrderStatus(String orderId, String newStatus, {String? trackingNumber, String? notes}) async {
    try {
      final updateData = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (trackingNumber != null) {
        updateData['tracking_number'] = trackingNumber;
      }

      await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      // Log status change
      await _logOrderStatusChange(orderId, newStatus, notes);

      // Send notification to customer
      await _notifyCustomerOfStatusChange(orderId, newStatus, trackingNumber);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> _logOrderStatusChange(String orderId, String newStatus, String? notes) async {
    try {
      await _supabase.from('order_status_logs').insert({
        'order_id': orderId,
        'status': newStatus,
        'notes': notes,
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw
      debugPrint('Failed to log order status change: $e');
    }
  }

  Future<void> _notifyCustomerOfStatusChange(String orderId, String newStatus, String? trackingNumber) async {
    try {
      // Get order details
      final orderResponse = await _supabase
          .from('orders')
          .select('user_id')
          .eq('id', orderId)
          .single();

      final userId = orderResponse['user_id'];

      // Create notification
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'order_update',
        'title': 'Order Status Update',
        'message': 'Your order $orderId status has been updated to: $newStatus${trackingNumber != null ? '. Tracking: $trackingNumber' : ''}',
        'data': {
          'order_id': orderId,
          'status': newStatus,
          'tracking_number': trackingNumber,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to notify customer: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, users(email), order_items(*)')
          .eq('status', status)
          .order('created_at', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSellerOrders(String sellerId, {String? status, int limit = 50}) async {
    try {
      var query = _supabase
          .from('orders')
          .select('*, users(email), order_items(*)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(limit);

      // Note: Status filtering would be implemented here in a real scenario

      final response = await query;
      return response;
    } catch (e) {
      throw Exception('Failed to get seller orders: $e');
    }
  }

  Future<void> assignOrderToSeller(String orderId, String sellerId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'seller_id': sellerId,
            'assigned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      await _logOrderStatusChange(orderId, 'assigned', 'Assigned to seller: $sellerId');
    } catch (e) {
      throw Exception('Failed to assign order to seller: $e');
    }
  }

  Future<void> processRefund(String orderId, double refundAmount, String reason) async {
    try {
      // Create refund record
      await _supabase.from('refunds').insert({
        'order_id': orderId,
        'amount': refundAmount,
        'reason': reason,
        'status': 'processing',
        'requested_at': DateTime.now().toIso8601String(),
      });

      // Update order status
      await updateOrderStatus(orderId, 'refund_requested', notes: 'Refund requested: $reason');

      // Notify customer
      await _notifyCustomerOfRefund(orderId, refundAmount, reason);
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  Future<void> _notifyCustomerOfRefund(String orderId, double refundAmount, String reason) async {
    try {
      final orderResponse = await _supabase
          .from('orders')
          .select('user_id')
          .eq('id', orderId)
          .single();

      final userId = orderResponse['user_id'];

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'refund',
        'title': 'Refund Requested',
        'message': 'A refund of \$${refundAmount.toStringAsFixed(2)} has been requested for order $orderId. Reason: $reason',
        'data': {
          'order_id': orderId,
          'refund_amount': refundAmount,
          'reason': reason,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to notify customer of refund: $e');
    }
  }

  Future<void> approveRefund(String refundId, String approvedBy) async {
    try {
      await _supabase
          .from('refunds')
          .update({
            'status': 'approved',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', refundId);

      // Get order ID and update order status
      final refund = await _supabase
          .from('refunds')
          .select('order_id')
          .eq('id', refundId)
          .single();

      await updateOrderStatus(refund['order_id'], 'refunded');
    } catch (e) {
      throw Exception('Failed to approve refund: $e');
    }
  }

  Future<void> rejectRefund(String refundId, String rejectedBy, String reason) async {
    try {
      await _supabase
          .from('refunds')
          .update({
            'status': 'rejected',
            'rejected_by': rejectedBy,
            'rejected_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
          })
          .eq('id', refundId);
    } catch (e) {
      throw Exception('Failed to reject refund: $e');
    }
  }

  Future<Map<String, dynamic>> getFulfillmentStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _supabase
          .from('orders')
          .select('status, created_at');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final orders = await query;

      final stats = <String, int>{
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
        'refunded': 0,
      };

      for (final order in orders) {
        final status = order['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return {
        'total_orders': orders.length,
        'status_breakdown': stats,
        'fulfillment_rate': orders.isNotEmpty ? (stats['delivered']! / orders.length) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to get fulfillment stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingFulfillmentTasks() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, users(email), order_items(*)')
          // Note: Status filtering for pending tasks would be implemented here
          .order('created_at', ascending: true)
          .limit(100);

      return response;
    } catch (e) {
      throw Exception('Failed to get pending fulfillment tasks: $e');
    }
  }

  Future<void> bulkUpdateOrderStatus(List<String> orderIds, String newStatus, {String? notes}) async {
    try {
      for (final orderId in orderIds) {
        await updateOrderStatus(orderId, newStatus, notes: notes);
      }
    } catch (e) {
      throw Exception('Failed to bulk update order status: $e');
    }
  }

  Future<void> addOrderNote(String orderId, String note, String addedBy) async {
    try {
      await _supabase.from('order_notes').insert({
        'order_id': orderId,
        'note': note,
        'added_by': addedBy,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add order note: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrderNotes(String orderId) async {
    try {
      final response = await _supabase
          .from('order_notes')
          .select('*, users(email)')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to get order notes: $e');
    }
  }
}