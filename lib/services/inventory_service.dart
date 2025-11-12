import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> updateStock(String productId, int newStock, {String? reason}) async {
    try {
      // Get current stock for logging
      final currentProduct = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      final oldStock = currentProduct['stock'] as int;

      // Update stock
      await _supabase
          .from('products')
          .update({'stock': newStock, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', productId);

      // Log stock change
      await _logStockChange(productId, oldStock, newStock, reason ?? 'Manual update');
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  Future<void> adjustStock(String productId, int adjustment, {String? reason}) async {
    try {
      // Get current stock
      final currentProduct = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      final currentStock = currentProduct['stock'] as int;
      final newStock = currentStock + adjustment;

      if (newStock < 0) {
        throw Exception('Insufficient stock. Current: $currentStock, Requested: ${adjustment.abs()}');
      }

      await updateStock(productId, newStock, reason: reason);
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }

  Future<void> _logStockChange(String productId, int oldStock, int newStock, String reason) async {
    try {
      await _supabase.from('stock_changes').insert({
        'product_id': productId,
        'old_stock': oldStock,
        'new_stock': newStock,
        'change_amount': newStock - oldStock,
        'reason': reason,
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to log stock change: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts({int threshold = 10}) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, sellers(*)')
          .gt('stock', 0)
          .lte('stock', threshold)
          .order('stock', ascending: true);

      return response;
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, sellers(*)')
          .eq('stock', 0)
          .order('updated_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to get out of stock products: $e');
    }
  }

  Future<Map<String, dynamic>> getInventoryStats(String? sellerId) async {
    try {
      var query = _supabase.from('products').select('stock, price');

      if (sellerId != null) {
        query = query.eq('seller_id', sellerId);
      }

      final products = await query;

      int totalProducts = products.length;
      int inStockProducts = 0;
      int outOfStockProducts = 0;
      int lowStockProducts = 0; // Less than 10
      double totalInventoryValue = 0;

      for (final product in products) {
        final stock = product['stock'] as int;
        final price = (product['price'] as num).toDouble();

        totalInventoryValue += stock * price;

        if (stock == 0) {
          outOfStockProducts++;
        } else {
          inStockProducts++;
          if (stock < 10) {
            lowStockProducts++;
          }
        }
      }

      return {
        'total_products': totalProducts,
        'in_stock_products': inStockProducts,
        'out_of_stock_products': outOfStockProducts,
        'low_stock_products': lowStockProducts,
        'total_inventory_value': totalInventoryValue,
      };
    } catch (e) {
      throw Exception('Failed to get inventory stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStockChangeHistory(String productId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('stock_changes')
          .select()
          .eq('product_id', productId)
          .order('changed_at', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      throw Exception('Failed to get stock change history: $e');
    }
  }

  Future<void> bulkUpdateStock(List<Map<String, dynamic>> updates) async {
    try {
      for (final update in updates) {
        final productId = update['product_id'];
        final newStock = update['stock'];
        final reason = update['reason'] ?? 'Bulk update';

        await updateStock(productId, newStock, reason: reason);
      }
    } catch (e) {
      throw Exception('Failed to bulk update stock: $e');
    }
  }

  Future<void> reserveStock(String productId, int quantity, String orderId) async {
    try {
      // Check if enough stock is available
      final product = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      final currentStock = product['stock'] as int;
      if (currentStock < quantity) {
        throw Exception('Insufficient stock for reservation');
      }

      // Create stock reservation
      await _supabase.from('stock_reservations').insert({
        'product_id': productId,
        'order_id': orderId,
        'quantity': quantity,
        'reserved_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(), // 24 hour hold
      });

      // Update available stock (this is a simplified approach)
      // In a real system, you might have separate available_stock field
      await adjustStock(productId, -quantity, reason: 'Stock reserved for order $orderId');
    } catch (e) {
      throw Exception('Failed to reserve stock: $e');
    }
  }

  Future<void> releaseStockReservation(String orderId) async {
    try {
      // Get reservations for this order
      final reservations = await _supabase
          .from('stock_reservations')
          .select('product_id, quantity')
          .eq('order_id', orderId)
          .eq('status', 'active');

      // Release stock back
      for (final reservation in reservations) {
        await adjustStock(
          reservation['product_id'],
          reservation['quantity'],
          reason: 'Stock reservation released for order $orderId',
        );
      }

      // Mark reservations as released
      await _supabase
          .from('stock_reservations')
          .update({'status': 'released', 'released_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId);
    } catch (e) {
      throw Exception('Failed to release stock reservation: $e');
    }
  }

  Future<void> confirmStockReservation(String orderId) async {
    try {
      // Mark reservations as confirmed (stock has been sold)
      await _supabase
          .from('stock_reservations')
          .update({'status': 'confirmed', 'confirmed_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId);
    } catch (e) {
      throw Exception('Failed to confirm stock reservation: $e');
    }
  }

  Future<void> cleanupExpiredReservations() async {
    try {
      // Find expired reservations
      final expiredReservations = await _supabase
          .from('stock_reservations')
          .select('product_id, quantity, order_id')
          .eq('status', 'active')
          .lt('expires_at', DateTime.now().toIso8601String());

      // Release stock back for expired reservations
      for (final reservation in expiredReservations) {
        await adjustStock(
          reservation['product_id'],
          reservation['quantity'],
          reason: 'Expired reservation released for order ${reservation['order_id']}',
        );
      }

      // Mark as expired
      await _supabase
          .from('stock_reservations')
          .update({'status': 'expired'})
          .eq('status', 'active')
          .lt('expires_at', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to cleanup expired reservations: $e');
    }
  }

  Future<bool> checkStockAvailability(String productId, int quantity) async {
    try {
      final product = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      return (product['stock'] as int) >= quantity;
    } catch (e) {
      throw Exception('Failed to check stock availability: $e');
    }
  }

  Future<void> setLowStockAlert(String productId, int threshold) async {
    try {
      await _supabase.from('stock_alerts').upsert({
        'product_id': productId,
        'threshold': threshold,
        'alert_type': 'low_stock',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to set low stock alert: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      final response = await _supabase
          .from('stock_alerts')
          .select('*, products(*)')
          .eq('is_active', true)
          .order('updated_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to get active alerts: $e');
    }
  }

  Future<void> processStockAlerts() async {
    try {
      final alerts = await getActiveAlerts();

      for (final alert in alerts) {
        final product = alert['products'];
        final currentStock = product['stock'] as int;
        final threshold = alert['threshold'] as int;

        if (currentStock <= threshold) {
          // Send alert notification
          await _sendStockAlertNotification(alert);
        }
      }
    } catch (e) {
      debugPrint('Failed to process stock alerts: $e');
    }
  }

  Future<void> _sendStockAlertNotification(Map<String, dynamic> alert) async {
    try {
      final product = alert['products'];
      final sellerId = product['seller_id'];

      await _supabase.from('notifications').insert({
        'user_id': sellerId,
        'type': 'inventory_alert',
        'title': 'Low Stock Alert',
        'message': 'Product "${product['name']}" is running low on stock (${product['stock']} remaining)',
        'data': {
          'product_id': product['id'],
          'current_stock': product['stock'],
          'threshold': alert['threshold'],
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to send stock alert notification: $e');
    }
  }
}