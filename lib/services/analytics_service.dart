import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> recordAnalyticsData(AnalyticsData data) async {
    try {
      await _supabase.from('analytics_data').upsert(data.toJson());
    } catch (e) {
      throw Exception('Failed to record analytics data: $e');
    }
  }

  Future<List<AnalyticsData>> getAnalyticsData(
    String sellerId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      var query = _supabase
          .from('analytics_data')
          .select()
          .eq('seller_id', sellerId)
          .order('date', ascending: false)
          .limit(limit);

      // Note: Date filtering would be implemented here in a real scenario

      final response = await query;
      return response.map((json) => AnalyticsData.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch analytics data: $e');
    }
  }

  Future<AnalyticsSummary> getAnalyticsSummary(
    String sellerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('analytics_summary')
          .select()
          .eq('seller_id', sellerId)
          .gte('period_start', startDate.toIso8601String())
          .lte('period_end', endDate.toIso8601String())
          .single();

      return AnalyticsSummary.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch analytics summary: $e');
    }
  }

  Future<void> updateAnalyticsData(String sellerId, DateTime date) async {
    try {
      // This would typically be called by a background job
      // Calculate metrics from orders, products, etc.
      final ordersResponse = await _supabase
          .from('orders')
          .select('total_amount, items')
          .eq('seller_id', sellerId)
          .gte('created_at', date.toIso8601String())
          .lt('created_at', date.add(const Duration(days: 1)).toIso8601String());

      final orders = ordersResponse as List<dynamic>;
      final totalOrders = orders.length;
      final totalRevenue = orders.fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      // Calculate other metrics...
      final analyticsData = AnalyticsData(
        id: '${sellerId}_${date.toIso8601String().split('T')[0]}',
        sellerId: sellerId,
        date: date,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        totalProductsSold: 0, // Calculate from order items
        uniqueCustomers: 0, // Calculate from unique user_ids
        averageOrderValue: totalOrders > 0 ? totalRevenue / totalOrders : 0,
        productSales: {}, // Calculate from order items
        categoryRevenue: {}, // Calculate from product categories
        createdAt: DateTime.now(),
      );

      await recordAnalyticsData(analyticsData);
    } catch (e) {
      throw Exception('Failed to update analytics data: $e');
    }
  }

  Future<Map<String, dynamic>> getTopProducts(String sellerId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('analytics_data')
          .select('product_sales')
          .eq('seller_id', sellerId)
          .order('date', ascending: false)
          .limit(1)
          .single();

      final productSales = response['product_sales'] as Map<String, dynamic>;
      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));

      return Map.fromEntries(sortedProducts.take(limit));
    } catch (e) {
      throw Exception('Failed to get top products: $e');
    }
  }

  Future<Map<String, dynamic>> getRevenueByCategory(String sellerId, {int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final response = await _supabase
          .from('analytics_data')
          .select('category_revenue')
          .eq('seller_id', sellerId)
          .gte('date', startDate.toIso8601String())
          .order('date', ascending: false);

      final categoryRevenue = <String, double>{};
      for (final record in response) {
        final categories = record['category_revenue'] as Map<String, dynamic>;
        categories.forEach((category, revenue) {
          categoryRevenue[category] = (categoryRevenue[category] ?? 0) + (revenue as num).toDouble();
        });
      }

      return categoryRevenue;
    } catch (e) {
      throw Exception('Failed to get revenue by category: $e');
    }
  }

  Future<Map<String, dynamic>> getSellerPerformanceMetrics(String sellerId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));

      final currentPeriod = await getAnalyticsData(sellerId, startDate: thirtyDaysAgo);
      final previousPeriod = await getAnalyticsData(sellerId, startDate: sixtyDaysAgo, endDate: thirtyDaysAgo);

      final currentRevenue = currentPeriod.fold<double>(0, (sum, data) => sum + data.totalRevenue);
      final previousRevenue = previousPeriod.fold<double>(0, (sum, data) => sum + data.totalRevenue);

      final revenueGrowth = previousRevenue > 0 ? ((currentRevenue - previousRevenue) / previousRevenue) * 100 : 0;

      return {
        'current_period_revenue': currentRevenue,
        'previous_period_revenue': previousRevenue,
        'revenue_growth_percentage': revenueGrowth,
        'total_orders_current': currentPeriod.fold<int>(0, (sum, data) => sum + data.totalOrders),
        'total_orders_previous': previousPeriod.fold<int>(0, (sum, data) => sum + data.totalOrders),
        'average_order_value': currentPeriod.isNotEmpty ? currentRevenue / currentPeriod.length : 0,
      };
    } catch (e) {
      throw Exception('Failed to get performance metrics: $e');
    }
  }
}