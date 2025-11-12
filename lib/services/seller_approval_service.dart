import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerApprovalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitSellerApplication({
    required String userId,
    required Map<String, dynamic> applicationData,
  }) async {
    try {
      // Check if user already has a pending or approved application
      final existingApplication = await _supabase
          .from('seller_applications')
          .select('status')
          .eq('user_id', userId)
          // Note: Status filtering would be implemented here in a real scenario
          .maybeSingle();

      if (existingApplication != null) {
        throw Exception('You already have a ${existingApplication['status']} seller application');
      }

      await _supabase.from('seller_applications').insert({
        'user_id': userId,
        'application_data': applicationData,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // Send notification to user
      await _notifyUserOfApplicationSubmission(userId);
    } catch (e) {
      throw Exception('Failed to submit seller application: $e');
    }
  }

  Future<void> _notifyUserOfApplicationSubmission(String userId) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'seller_application',
        'title': 'Seller Application Submitted',
        'message': 'Your seller application has been submitted and is under review. You will be notified once a decision is made.',
        'data': {'application_status': 'submitted'},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
debugPrint('Failed to notify user of application submission: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingApplications({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('seller_applications')
          .select('*, users(email, first_name, last_name)')
          .eq('status', 'pending')
          .order('submitted_at', ascending: true)
          .limit(limit);

      return response;
    } catch (e) {
      throw Exception('Failed to get pending applications: $e');
    }
  }

  Future<void> approveSellerApplication(String applicationId, String approvedBy, {DateTime? expiryDate}) async {
    try {
      // Get application details
      final application = await _supabase
          .from('seller_applications')
          .select('user_id, application_data')
          .eq('id', applicationId)
          .single();

      final userId = application['user_id'];
      final defaultExpiry = DateTime.now().add(const Duration(days: 365)); // 1 year default

      // Create seller record
      await _supabase.from('sellers').insert({
        'id': userId, // Use user ID as seller ID
        'created_by': approvedBy,
        'expires_at': (expiryDate ?? defaultExpiry).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update application status
      await _supabase
          .from('seller_applications')
          .update({
            'status': 'approved',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
            'expiry_date': (expiryDate ?? defaultExpiry).toIso8601String(),
          })
          .eq('id', applicationId);

      // Send approval notification
      await _notifyUserOfApproval(userId, expiryDate ?? defaultExpiry);
    } catch (e) {
      throw Exception('Failed to approve seller application: $e');
    }
  }

  Future<void> _notifyUserOfApproval(String userId, DateTime expiryDate) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'seller_approval',
        'title': 'Seller Account Approved!',
        'message': 'Congratulations! Your seller account has been approved. You can now start selling on our platform.',
        'data': {
          'approval_date': DateTime.now().toIso8601String(),
          'expiry_date': expiryDate.toIso8601String(),
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
debugPrint('Failed to notify user of approval: $e');
    }
  }

  Future<void> rejectSellerApplication(String applicationId, String rejectedBy, String reason) async {
    try {
      // Get application details
      final application = await _supabase
          .from('seller_applications')
          .select('user_id')
          .eq('id', applicationId)
          .single();

      final userId = application['user_id'];

      // Update application status
      await _supabase
          .from('seller_applications')
          .update({
            'status': 'rejected',
            'rejected_by': rejectedBy,
            'rejected_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
          })
          .eq('id', applicationId);

      // Send rejection notification
      await _notifyUserOfRejection(userId, reason);
    } catch (e) {
      throw Exception('Failed to reject seller application: $e');
    }
  }

  Future<void> _notifyUserOfRejection(String userId, String reason) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'seller_rejection',
        'title': 'Seller Application Update',
        'message': 'Unfortunately, your seller application has been rejected. Reason: $reason',
        'data': {
          'rejection_reason': reason,
          'can_reapply': true,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
debugPrint('Failed to notify user of rejection: $e');
    }
  }

  Future<void> extendSellerSubscription(String sellerId, Duration extension, String extendedBy) async {
    try {
      // Get current seller
      final seller = await _supabase
          .from('sellers')
          .select('expires_at')
          .eq('id', sellerId)
          .single();

      final currentExpiry = DateTime.parse(seller['expires_at']);
      final newExpiry = currentExpiry.add(extension);

      // Update expiry date
      await _supabase
          .from('sellers')
          .update({
            'expires_at': newExpiry.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerId);

      // Log extension
      await _logSellerExtension(sellerId, extension, extendedBy);

      // Send notification
      await _notifyUserOfExtension(sellerId, newExpiry);
    } catch (e) {
      throw Exception('Failed to extend seller subscription: $e');
    }
  }

  Future<void> _logSellerExtension(String sellerId, Duration extension, String extendedBy) async {
    try {
      await _supabase.from('seller_extensions').insert({
        'seller_id': sellerId,
        'extension_days': extension.inDays,
        'extended_by': extendedBy,
        'extended_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
debugPrint('Failed to log seller extension: $e');
    }
  }

  Future<void> _notifyUserOfExtension(String sellerId, DateTime newExpiry) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': sellerId,
        'type': 'seller_expiry',
        'title': 'Seller Subscription Extended',
        'message': 'Your seller subscription has been extended. New expiry date: ${newExpiry.toString().split(' ')[0]}',
        'data': {
          'new_expiry_date': newExpiry.toIso8601String(),
          'extension_type': 'manual',
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
debugPrint('Failed to notify user of extension: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExpiringSellers({int daysUntilExpiry = 30}) async {
    try {
      final expiryThreshold = DateTime.now().add(Duration(days: daysUntilExpiry));

      final response = await _supabase
          .from('sellers')
          .select('*, users(email, first_name, last_name)')
          .lte('expires_at', expiryThreshold.toIso8601String())
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: true);

      return response;
    } catch (e) {
      throw Exception('Failed to get expiring sellers: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExpiredSellers() async {
    try {
      final response = await _supabase
          .from('sellers')
          .select('*, users(email, first_name, last_name)')
          .lt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to get expired sellers: $e');
    }
  }

  Future<void> deactivateExpiredSellers() async {
    try {
      // Get expired sellers
      final expiredSellers = await getExpiredSellers();

      for (final seller in expiredSellers) {
        final sellerId = seller['id'];

        // Mark products as inactive (or delete them based on policy)
        await _supabase
            .from('products')
            .update({'is_active': false})
            .eq('seller_id', sellerId);

        // Send expiry notification
        await _notifyUserOfExpiry(sellerId);
      }
    } catch (e) {
debugPrint('Failed to deactivate expired sellers: $e');
    }
  }

  Future<void> _notifyUserOfExpiry(String sellerId) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': sellerId,
        'type': 'seller_expiry',
        'title': 'Seller Account Expired',
        'message': 'Your seller account has expired. Please contact support to renew your subscription.',
        'data': {
          'expiry_date': DateTime.now().toIso8601String(),
          'can_renew': true,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
debugPrint('Failed to notify user of expiry: $e');
    }
  }

  Future<Map<String, dynamic>> getSellerApplicationStats() async {
    try {
      final response = await _supabase
          .from('seller_applications')
          .select('status');

      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (final application in response) {
        switch (application['status']) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return {
        'pending_applications': pending,
        'approved_applications': approved,
        'rejected_applications': rejected,
        'total_applications': response.length,
      };
    } catch (e) {
      throw Exception('Failed to get seller application stats: $e');
    }
  }

  Future<Map<String, dynamic>> getSellerSubscriptionStats() async {
    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      final activeSellers = await _supabase
          .from('sellers')
          .select()
          .gt('expires_at', now.toIso8601String());

      final expiringSoon = await _supabase
          .from('sellers')
          .select()
          .gt('expires_at', now.toIso8601String())
          .lte('expires_at', thirtyDaysFromNow.toIso8601String());

      final expired = await _supabase
          .from('sellers')
          .select()
          .lt('expires_at', now.toIso8601String());

      return {
        'active_sellers': activeSellers.length,
        'expiring_soon': expiringSoon.length,
        'expired_sellers': expired.length,
        'total_sellers': activeSellers.length + expired.length,
      };
    } catch (e) {
      throw Exception('Failed to get seller subscription stats: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserApplicationStatus(String userId) async {
    try {
      final response = await _supabase
          .from('seller_applications')
          .select()
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get user application status: $e');
    }
  }

  Future<bool> isUserApprovedSeller(String userId) async {
    try {
      final response = await _supabase
          .from('sellers')
          .select()
          .eq('id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}