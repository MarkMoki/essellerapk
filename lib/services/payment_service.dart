import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('$darajaBaseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$darajaConsumerKey:$darajaConsumerSecret'))}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Failed to get access token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while getting access token: $e');
    }
  }

  Future<Map<String, dynamic>> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String orderId,
    String? description,
  }) async {
    try {
      final accessToken = await getAccessToken();
      final timestamp = DateTime.now().toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.')[0];
      final password = base64Encode(utf8.encode('$darajaShortcode$darajaPasskey$timestamp'));

      final response = await http.post(
        Uri.parse('$darajaBaseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'BusinessShortCode': darajaShortcode,
          'Password': password,
          'Timestamp': timestamp,
          'TransactionType': 'CustomerPayBillOnline',
          'Amount': amount.toInt(),
          'PartyA': phoneNumber,
          'PartyB': darajaShortcode,
          'PhoneNumber': phoneNumber,
          'CallBackURL': '$supabaseUrl/functions/v1/payment-callback',
          'AccountReference': orderId,
          'TransactionDesc': description ?? 'Payment for order $orderId',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Store payment initiation record
        await _recordPaymentInitiation(
          orderId: orderId,
          amount: amount,
          phoneNumber: phoneNumber,
          checkoutRequestId: data['CheckoutRequestID'],
        );
        return data;
      } else {
        throw Exception('Failed to initiate STK Push: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while initiating STK Push: $e');
    }
  }

  Future<void> _recordPaymentInitiation({
    required String orderId,
    required double amount,
    required String phoneNumber,
    required String checkoutRequestId,
  }) async {
    try {
      await _supabase.from('payment_initiations').insert({
        'order_id': orderId,
        'amount': amount,
        'phone_number': phoneNumber,
        'checkout_request_id': checkoutRequestId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to record payment initiation: $e');
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String checkoutRequestId) async {
    try {
      final accessToken = await getAccessToken();

      final response = await http.post(
        Uri.parse('$darajaBaseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'BusinessShortCode': darajaShortcode,
          'Password': base64Encode(utf8.encode('$darajaShortcode$darajaPasskey${DateTime.now().toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.')[0]}')),
          'Timestamp': DateTime.now().toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.')[0],
          'CheckoutRequestID': checkoutRequestId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check payment status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while checking payment status: $e');
    }
  }

  Future<void> processPaymentCallback(Map<String, dynamic> callbackData) async {
    try {
      final body = callbackData['Body']['stkCallback'];
      final resultCode = body['ResultCode'];
      final checkoutRequestId = body['CheckoutRequestID'];

      // Update payment initiation status
      await _supabase
          .from('payment_initiations')
          .update({
            'status': resultCode == 0 ? 'completed' : 'failed',
            'callback_data': callbackData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('checkout_request_id', checkoutRequestId);

      if (resultCode == 0) {
        // Payment successful
        final callbackMetadata = body['CallbackMetadata']['Item'] as List;
        final amount = callbackMetadata.firstWhere((item) => item['Name'] == 'Amount')['Value'];
        final mpesaReceiptNumber = callbackMetadata.firstWhere((item) => item['Name'] == 'MpesaReceiptNumber')['Value'];
        final transactionDate = callbackMetadata.firstWhere((item) => item['Name'] == 'TransactionDate')['Value'];
        final phoneNumber = callbackMetadata.firstWhere((item) => item['Name'] == 'PhoneNumber')['Value'];

        // Get order ID from payment initiation
        final paymentRecord = await _supabase
            .from('payment_initiations')
            .select('order_id')
            .eq('checkout_request_id', checkoutRequestId)
            .single();

        final orderId = paymentRecord['order_id'];

        // Update order status
        await _supabase
            .from('orders')
            .update({
              'status': 'paid',
              'payment_date': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId);

        // Record transaction
        await _recordTransaction(
          orderId: orderId,
          amount: amount.toDouble(),
          mpesaReceiptNumber: mpesaReceiptNumber,
          transactionDate: transactionDate,
          phoneNumber: phoneNumber.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error processing payment callback: $e');
      throw Exception('Failed to process payment callback: $e');
    }
  }

  Future<void> _recordTransaction({
    required String orderId,
    required double amount,
    required String mpesaReceiptNumber,
    required String transactionDate,
    required String phoneNumber,
  }) async {
    try {
      await _supabase.from('transactions').insert({
        'order_id': orderId,
        'amount': amount,
        'mpesa_receipt_number': mpesaReceiptNumber,
        'transaction_date': transactionDate,
        'phone_number': phoneNumber,
        'payment_method': 'mpesa',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to record transaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('payment_initiations')
          .select('*, orders(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentStats(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await _supabase
          .from('payment_initiations')
          .select('status, amount')
          .eq('user_id', userId)
          .gte('created_at', thirtyDaysAgo.toIso8601String());

      int successfulPayments = 0;
      int failedPayments = 0;
      double totalAmount = 0;

      for (final payment in response) {
        if (payment['status'] == 'completed') {
          successfulPayments++;
          totalAmount += (payment['amount'] as num).toDouble();
        } else if (payment['status'] == 'failed') {
          failedPayments++;
        }
      }

      return {
        'successful_payments': successfulPayments,
        'failed_payments': failedPayments,
        'total_amount': totalAmount,
        'success_rate': successfulPayments + failedPayments > 0
            ? (successfulPayments / (successfulPayments + failedPayments)) * 100
            : 0,
      };
    } catch (e) {
      throw Exception('Failed to get payment stats: $e');
    }
  }
}