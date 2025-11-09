 import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  Future<bool> isDatabaseReachable() async {
    try {
      // Simple query to check database connectivity
      await _supabase.from('products').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, bool>> checkConnectivity() async {
    final hasInternet = await isConnected();
    final hasDatabase = hasInternet ? await isDatabaseReachable() : false;

    return {
      'internet': hasInternet,
      'database': hasDatabase,
    };
  }

  Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
}