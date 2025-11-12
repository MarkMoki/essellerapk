import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderTrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getOrderTracking(String orderId, String userId) async {
    try {
      // Get order details
      final orderResponse = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .eq('user_id', userId)
          .single();

      if (orderResponse.isEmpty) return null;

      // Get tracking updates
      final trackingResponse = await _supabase
          .from('order_tracking')
          .select()
          .eq('order_id', orderId)
          .order('timestamp', ascending: true);

      // Generate tracking steps based on order status and tracking data
      final trackingSteps = _generateTrackingSteps(orderResponse['status'], trackingResponse);

      return {
        'order': orderResponse,
        'tracking_steps': trackingSteps,
        'carrier_info': await _getCarrierInfo(orderId),
      };
    } catch (e) {
      debugPrint('Error fetching order tracking: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _generateTrackingSteps(String orderStatus, List<dynamic> trackingData) {
    final steps = [
      {
        'status': 'Order Placed',
        'description': 'Your order has been received and is being processed',
        'completed': true,
        'icon': Icons.shopping_cart,
      },
      {
        'status': 'Payment Confirmed',
        'description': 'Payment has been successfully processed',
        'completed': ['paid', 'processing', 'shipped', 'out_for_delivery', 'delivered'].contains(orderStatus),
        'icon': Icons.payment,
      },
      {
        'status': 'Order Processing',
        'description': 'Your order is being prepared for shipment',
        'completed': ['processing', 'shipped', 'out_for_delivery', 'delivered'].contains(orderStatus),
        'icon': Icons.inventory,
      },
      {
        'status': 'Shipped',
        'description': 'Your order has been shipped and is on its way',
        'completed': ['shipped', 'out_for_delivery', 'delivered'].contains(orderStatus),
        'icon': Icons.local_shipping,
      },
      {
        'status': 'Out for Delivery',
        'description': 'Your order is out for delivery',
        'completed': ['out_for_delivery', 'delivered'].contains(orderStatus),
        'icon': Icons.delivery_dining,
      },
      {
        'status': 'Delivered',
        'description': 'Your order has been delivered successfully',
        'completed': orderStatus == 'delivered',
        'icon': Icons.check_circle,
      },
    ];

    // Add timestamps from tracking data
    for (final tracking in trackingData) {
      final trackingStatus = tracking['status'] as String;
      final step = steps.firstWhere(
        (s) => (s['status'] as String).toLowerCase().replaceAll(' ', '_') == trackingStatus,
        orElse: () => <String, Object>{},
      );

      if (step.isNotEmpty) {
        step['timestamp'] = tracking['timestamp'];
        step['description'] = tracking['description'] ?? step['description'];
      }
    }

    return steps;
  }

  Future<Map<String, dynamic>?> _getCarrierInfo(String orderId) async {
    try {
      final response = await _supabase
          .from('order_shipments')
          .select('carrier_name, tracking_number, estimated_delivery')
          .eq('order_id', orderId)
          .single();

      return {
        'carrier': response['carrier_name'] ?? 'Unknown Carrier',
        'trackingNumber': response['tracking_number'] ?? 'Not available',
        'estimatedDelivery': response['estimated_delivery'],
      };
    } catch (e) {
      return {
        'carrier': 'Processing',
        'trackingNumber': 'Not available yet',
        'estimatedDelivery': null,
      };
    }
  }

  Future<void> addTrackingUpdate({
    required String orderId,
    required String status,
    required String description,
    String? location,
  }) async {
    try {
      await _supabase.from('order_tracking').insert({
        'order_id': orderId,
        'status': status,
        'description': description,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add tracking update: $e');
    }
  }

  Future<void> updateShipmentInfo({
    required String orderId,
    required String carrierName,
    required String trackingNumber,
    DateTime? estimatedDelivery,
  }) async {
    try {
      await _supabase.from('order_shipments').upsert({
        'order_id': orderId,
        'carrier_name': carrierName,
        'tracking_number': trackingNumber,
        'estimated_delivery': estimatedDelivery?.toIso8601String(),
        'shipped_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update shipment info: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentTrackingUpdates(String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('order_tracking')
          .select('*, orders(id, status)')
          .eq('orders.user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get recent tracking updates: $e');
    }
  }
}