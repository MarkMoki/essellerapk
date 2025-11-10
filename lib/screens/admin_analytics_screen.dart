import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class AnalyticsData {
  final int totalProducts;
  final int totalOrders;
  final int totalUsers;
  final double totalRevenue;
  final int pendingOrders;
  final int shippedOrders;
  final int deliveredOrders;

  AnalyticsData({
    required this.totalProducts,
    required this.totalOrders,
    required this.totalUsers,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
  });
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  AnalyticsData? _analytics;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Fetch analytics data
      final productsResponse = await _supabase.from('products').select('id');
      final ordersResponse = await _supabase.from('orders').select('status, total_amount');
      final usersResponse = await _supabase.from('profiles').select('id');

      final totalProducts = productsResponse.length;
      final totalOrders = ordersResponse.length;
      final totalUsers = usersResponse.length;

      double totalRevenue = 0;
      int pendingOrders = 0;
      int shippedOrders = 0;
      int deliveredOrders = 0;

      for (final order in ordersResponse) {
        final status = order['status'];
        final amount = order['total_amount'] as num? ?? 0;

        if (status == 'paid' || status == 'shipped' || status == 'delivered') {
          totalRevenue += amount.toDouble();
        }

        switch (status) {
          case 'pending_payment':
            pendingOrders++;
            break;
          case 'paid':
            pendingOrders++;
            break;
          case 'shipped':
            shippedOrders++;
            break;
          case 'delivered':
            deliveredOrders++;
            break;
        }
      }

      if (mounted) {
        setState(() {
          _analytics = AnalyticsData(
            totalProducts: totalProducts,
            totalOrders: totalOrders,
            totalUsers: totalUsers,
            totalRevenue: totalRevenue,
            pendingOrders: pendingOrders,
            shippedOrders: shippedOrders,
            deliveredOrders: deliveredOrders,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAnalytics,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Admin - Analytics'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
            ],
          ),
        ),
        child: LoadingOverlay(
          isLoading: _isLoading,
          loadingMessage: 'Loading analytics...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Analytics',
                  message: _errorMessage,
                  onRetry: _loadAnalytics,
                  icon: Icons.refresh,
                )
              : _analytics == null
                  ? const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAnalytics,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildMetricCard(
                            'Total Products',
                            _analytics!.totalProducts.toString(),
                            Icons.inventory,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Total Orders',
                            _analytics!.totalOrders.toString(),
                            Icons.shopping_cart,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Total Users',
                            _analytics!.totalUsers.toString(),
                            Icons.people,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Total Revenue',
                            'Ksh${_analytics!.totalRevenue.toStringAsFixed(2)}',
                            Icons.attach_money,
                            Colors.orange,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Order Status Breakdown',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Pending Orders',
                            _analytics!.pendingOrders.toString(),
                            Icons.pending,
                            Colors.yellow,
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Shipped Orders',
                            _analytics!.shippedOrders.toString(),
                            Icons.local_shipping,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Delivered Orders',
                            _analytics!.deliveredOrders.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}