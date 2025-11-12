import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PayoutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createPayoutRequest({
    required String sellerId,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      // Check if seller has sufficient balance
      final balance = await getSellerBalance(sellerId);
      if (balance < amount) {
        throw Exception('Insufficient balance for payout');
      }

      await _supabase.from('payout_requests').insert({
        'seller_id': sellerId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_details': paymentDetails,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create payout request: $e');
    }
  }

  Future<double> getSellerBalance(String sellerId) async {
    try {
      // Calculate balance from completed orders minus previous payouts
      final ordersResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('seller_id', sellerId)
          .eq('status', 'delivered');

      final payoutsResponse = await _supabase
          .from('payout_requests')
          .select('amount')
          .eq('seller_id', sellerId)
          .eq('status', 'completed');

      double totalEarnings = 0;
      for (final order in ordersResponse) {
        totalEarnings += (order['total_amount'] as num).toDouble();
      }

      double totalPayouts = 0;
      for (final payout in payoutsResponse) {
        totalPayouts += (payout['amount'] as num).toDouble();
      }

      return totalEarnings - totalPayouts;
    } catch (e) {
      throw Exception('Failed to get seller balance: $e');
    }
  }

  Future<void> processPayout(String payoutId, String processedBy) async {
    try {
      await _supabase
          .from('payout_requests')
          .update({
            'status': 'processing',
            'processed_by': processedBy,
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payoutId);
    } catch (e) {
      throw Exception('Failed to process payout: $e');
    }
  }

  Future<void> completePayout(String payoutId) async {
    try {
      await _supabase
          .from('payout_requests')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', payoutId);

      // Log the transaction
      final payout = await _supabase
          .from('payout_requests')
          .select('seller_id, amount')
          .eq('id', payoutId)
          .single();

      await _logPayoutTransaction(payout['seller_id'], payout['amount'], 'completed');
    } catch (e) {
      throw Exception('Failed to complete payout: $e');
    }
  }

  Future<void> rejectPayout(String payoutId, String rejectedBy, String reason) async {
    try {
      await _supabase
          .from('payout_requests')
          .update({
            'status': 'rejected',
            'rejected_by': rejectedBy,
            'rejected_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
          })
          .eq('id', payoutId);
    } catch (e) {
      throw Exception('Failed to reject payout: $e');
    }
  }

  Future<void> _logPayoutTransaction(String sellerId, double amount, String status) async {
    try {
      await _supabase.from('payout_transactions').insert({
        'seller_id': sellerId,
        'amount': amount,
        'type': 'payout',
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to log payout transaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPayoutRequests({
    String? sellerId,
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('payout_requests')
          .select('*, sellers(*)')
          .order('requested_at', ascending: false)
          .limit(limit);

      // Note: Filtering would be implemented here in a real scenario

      final response = await query;
      return response;
    } catch (e) {
      throw Exception('Failed to get payout requests: $e');
    }
  }

  Future<Map<String, dynamic>> getPayoutStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _supabase
          .from('payout_requests')
          .select('status, amount, requested_at');

      if (startDate != null) {
        query = query.gte('requested_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('requested_at', endDate.toIso8601String());
      }

      final payouts = await query;

      double totalPaid = 0;
      double totalPending = 0;
      double totalRejected = 0;
      int completedCount = 0;
      int pendingCount = 0;
      int rejectedCount = 0;

      for (final payout in payouts) {
        final amount = (payout['amount'] as num).toDouble();
        final status = payout['status'];

        switch (status) {
          case 'completed':
            totalPaid += amount;
            completedCount++;
            break;
          case 'pending':
            totalPending += amount;
            pendingCount++;
            break;
          case 'rejected':
            totalRejected += amount;
            rejectedCount++;
            break;
        }
      }

      return {
        'total_paid': totalPaid,
        'total_pending': totalPending,
        'total_rejected': totalRejected,
        'completed_count': completedCount,
        'pending_count': pendingCount,
        'rejected_count': rejectedCount,
        'total_requests': payouts.length,
      };
    } catch (e) {
      throw Exception('Failed to get payout stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSellerPayoutHistory(String sellerId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('payout_requests')
          .select()
          .eq('seller_id', sellerId)
          .order('requested_at', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      throw Exception('Failed to get seller payout history: $e');
    }
  }

  Future<void> scheduleAutomaticPayouts() async {
    try {
      // Get sellers eligible for automatic payouts (based on balance threshold)
      final eligibleSellers = await _supabase
          .from('sellers')
          .select('id, automatic_payout_threshold')
          .not('automatic_payout_threshold', 'is', null);

      for (final seller in eligibleSellers) {
        final sellerId = seller['id'];
        final threshold = (seller['automatic_payout_threshold'] as num).toDouble();
        final balance = await getSellerBalance(sellerId);

        if (balance >= threshold) {
          // Get seller's default payout method
          final payoutMethod = await _getSellerDefaultPayoutMethod(sellerId);
          if (payoutMethod != null) {
            await createPayoutRequest(
              sellerId: sellerId,
              amount: balance,
              paymentMethod: payoutMethod['method'],
              paymentDetails: payoutMethod['details'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to schedule automatic payouts: $e');
    }
  }

  Future<Map<String, dynamic>?> _getSellerDefaultPayoutMethod(String sellerId) async {
    try {
      final response = await _supabase
          .from('seller_payout_methods')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_default', true)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> addPayoutMethod({
    required String sellerId,
    required String method,
    required Map<String, dynamic> details,
    bool isDefault = false,
  }) async {
    try {
      if (isDefault) {
        // Remove default flag from other methods
        await _supabase
            .from('seller_payout_methods')
            .update({'is_default': false})
            .eq('seller_id', sellerId);
      }

      await _supabase.from('seller_payout_methods').insert({
        'seller_id': sellerId,
        'method': method,
        'details': details,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add payout method: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSellerPayoutMethods(String sellerId) async {
    try {
      final response = await _supabase
          .from('seller_payout_methods')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to get seller payout methods: $e');
    }
  }

  Future<void> calculatePlatformFees(String orderId) async {
    try {
      // Calculate platform fees for the order
      final order = await _supabase
          .from('orders')
          .select('total_amount, seller_id')
          .eq('id', orderId)
          .single();

      final totalAmount = (order['total_amount'] as num).toDouble();
      const platformFeePercentage = 0.05; // 5% platform fee
      final platformFee = totalAmount * platformFeePercentage;

      await _supabase.from('platform_fees').insert({
        'order_id': orderId,
        'seller_id': order['seller_id'],
        'amount': platformFee,
        'percentage': platformFeePercentage,
        'calculated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to calculate platform fees: $e');
    }
  }
}