import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> sendWelcomeEmail({
    required String toEmail,
    required String userName,
  }) async {
    try {
      await _sendEmail(
        to: toEmail,
        subject: 'Welcome to ESeller APK!',
        template: 'welcome',
        templateData: {
          'user_name': userName,
          'login_url': 'https://esellerapk.com/login',
        },
      );
    } catch (e) {
      throw Exception('Failed to send welcome email: $e');
    }
  }

  Future<void> sendOrderConfirmationEmail({
    required String toEmail,
    required String userName,
    required String orderId,
    required double orderTotal,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    try {
      await _sendEmail(
        to: toEmail,
        subject: 'Order Confirmation - $orderId',
        template: 'order_confirmation',
        templateData: {
          'user_name': userName,
          'order_id': orderId,
          'order_total': orderTotal.toStringAsFixed(2),
          'order_items': orderItems,
          'order_url': 'https://esellerapk.com/orders/$orderId',
        },
      );
    } catch (e) {
      throw Exception('Failed to send order confirmation email: $e');
    }
  }

  Future<void> sendOrderStatusUpdateEmail({
    required String toEmail,
    required String userName,
    required String orderId,
    required String newStatus,
    String? trackingNumber,
  }) async {
    try {
      await _sendEmail(
        to: toEmail,
        subject: 'Order Update - $orderId',
        template: 'order_status_update',
        templateData: {
          'user_name': userName,
          'order_id': orderId,
          'new_status': newStatus,
          'tracking_number': trackingNumber,
          'order_url': 'https://esellerapk.com/orders/$orderId',
        },
      );
    } catch (e) {
      throw Exception('Failed to send order status update email: $e');
    }
  }

  Future<void> sendSellerApprovalEmail({
    required String toEmail,
    required String sellerName,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    try {
      final subject = isApproved ? 'Seller Account Approved!' : 'Seller Application Update';
      final template = isApproved ? 'seller_approved' : 'seller_rejected';

      await _sendEmail(
        to: toEmail,
        subject: subject,
        template: template,
        templateData: {
          'seller_name': sellerName,
          'rejection_reason': rejectionReason,
          'dashboard_url': 'https://esellerapk.com/seller/dashboard',
        },
      );
    } catch (e) {
      throw Exception('Failed to send seller approval email: $e');
    }
  }

  Future<void> sendSellerExpiryWarningEmail({
    required String toEmail,
    required String sellerName,
    required DateTime expiryDate,
  }) async {
    try {
      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

      await _sendEmail(
        to: toEmail,
        subject: 'Seller Account Expiring Soon',
        template: 'seller_expiry_warning',
        templateData: {
          'seller_name': sellerName,
          'expiry_date': expiryDate.toIso8601String(),
          'days_until_expiry': daysUntilExpiry,
          'renewal_url': 'https://esellerapk.com/seller/renewal',
        },
      );
    } catch (e) {
      throw Exception('Failed to send seller expiry warning email: $e');
    }
  }

  Future<void> sendPayoutNotificationEmail({
    required String toEmail,
    required String sellerName,
    required double payoutAmount,
    required String payoutMethod,
  }) async {
    try {
      await _sendEmail(
        to: toEmail,
        subject: 'Payout Processed - \$${payoutAmount.toStringAsFixed(2)}',
        template: 'payout_notification',
        templateData: {
          'seller_name': sellerName,
          'payout_amount': payoutAmount.toStringAsFixed(2),
          'payout_method': payoutMethod,
          'payouts_url': 'https://esellerapk.com/seller/payouts',
        },
      );
    } catch (e) {
      throw Exception('Failed to send payout notification email: $e');
    }
  }

  Future<void> sendPasswordResetEmail({
    required String toEmail,
    required String userName,
    required String resetToken,
  }) async {
    try {
      await _sendEmail(
        to: toEmail,
        subject: 'Password Reset Request',
        template: 'password_reset',
        templateData: {
          'user_name': userName,
          'reset_url': 'https://esellerapk.com/reset-password?token=$resetToken',
          'reset_token': resetToken,
        },
      );
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  Future<void> sendReviewNotificationEmail({
    required String toEmail,
    required String sellerName,
    required String productName,
    required int rating,
    required String reviewText,
  }) async {
    try {
      await _sendEmail(
        to: toEmail,
        subject: 'New Review on $productName',
        template: 'review_notification',
        templateData: {
          'seller_name': sellerName,
          'product_name': productName,
          'rating': rating,
          'review_text': reviewText,
          'reviews_url': 'https://esellerapk.com/seller/reviews',
        },
      );
    } catch (e) {
      throw Exception('Failed to send review notification email: $e');
    }
  }

  Future<void> sendNewsletterEmail({
    required List<String> toEmails,
    required String subject,
    required String content,
    required String newsletterId,
  }) async {
    try {
      for (final email in toEmails) {
        await _sendEmail(
          to: email,
          subject: subject,
          template: 'newsletter',
          templateData: {
            'content': content,
            'newsletter_id': newsletterId,
            'unsubscribe_url': 'https://esellerapk.com/unsubscribe?email=$email',
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to send newsletter emails: $e');
    }
  }

  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String template,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      // Using Supabase Edge Functions for email sending
      final response = await _supabase.functions.invoke(
        'send-email',
        body: {
          'to': to,
          'subject': subject,
          'template': template,
          'templateData': templateData,
        },
      );

      if (response.status != 200) {
        throw Exception('Email service returned status: ${response.status}');
      }

      // Log email sent
      await _logEmail(
        to: to,
        subject: subject,
        template: template,
        status: 'sent',
      );
    } catch (e) {
      // Log email failed
      await _logEmail(
        to: to,
        subject: subject,
        template: template,
        status: 'failed',
        error: e.toString(),
      );
      throw Exception('Failed to send email: $e');
    }
  }

  Future<void> _logEmail({
    required String to,
    required String subject,
    required String template,
    required String status,
    String? error,
  }) async {
    try {
      await _supabase.from('email_logs').insert({
        'to_email': to,
        'subject': subject,
        'template': template,
        'status': status,
        'error': error,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't throw here to avoid cascading failures
      debugPrint('Failed to log email: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEmailLogs({
    String? userEmail,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('email_logs')
          .select()
          .order('sent_at', ascending: false)
          .limit(limit);

      // Note: Email filtering would be implemented here in a real scenario

      final response = await query;
      return response;
    } catch (e) {
      throw Exception('Failed to get email logs: $e');
    }
  }

  Future<Map<String, dynamic>> getEmailStats({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('email_logs')
          .select('status, template')
          .gte('sent_at', startDate.toIso8601String());

      int totalSent = 0;
      int totalFailed = 0;
      final templateStats = <String, int>{};

      for (final log in response) {
        if (log['status'] == 'sent') {
          totalSent++;
        } else if (log['status'] == 'failed') {
          totalFailed++;
        }

        final template = log['template'] as String;
        templateStats[template] = (templateStats[template] ?? 0) + 1;
      }

      return {
        'total_sent': totalSent,
        'total_failed': totalFailed,
        'success_rate': totalSent + totalFailed > 0 ? (totalSent / (totalSent + totalFailed)) * 100 : 0,
        'template_stats': templateStats,
      };
    } catch (e) {
      throw Exception('Failed to get email stats: $e');
    }
  }
}