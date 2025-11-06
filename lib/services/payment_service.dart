import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class PaymentService {
  Future<String> getAccessToken() async {
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
      throw Exception('Failed to get access token');
    }
  }

  Future<Map<String, dynamic>> initiateSTKPush(String phoneNumber, double amount, String orderId) async {
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
        'CallBackURL': 'https://your-callback-url.com/callback', // Replace with actual
        'AccountReference': orderId,
        'TransactionDesc': 'Payment for order $orderId',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to initiate STK Push');
    }
  }
}