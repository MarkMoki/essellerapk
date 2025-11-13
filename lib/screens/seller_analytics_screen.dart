import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../widgets/access_denied_screen.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Analytics data
  int _totalProducts = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  int _totalViews = 0;
  Map<String, dynamic> _monthlyStats = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sellerId = authProvider.user!.id;

      // Load product count
      final productsResponse = await _supabase
          .from('products')
          .select('id')
          .eq('seller_id', sellerId);

      _totalProducts = productsResponse.length;

      // Load order count and revenue (simplified - would need order_items table)
      final ordersResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('status', 'delivered'); // Only count completed orders

      _totalOrders = ordersResponse.length;
      _totalRevenue = ordersResponse.fold<double>(
        0.0,
        (sum, order) => sum + (order['total_amount'] as num).toDouble(),
      );

      // Load views (placeholder - would need analytics tracking)
      _totalViews = 0;

      // Load monthly stats (placeholder)
      _monthlyStats = {
        'thisMonth': {
          'orders': 0,
          'revenue': 0.0,
          'views': 0,
        },
        'lastMonth': {
          'orders': 0,
          'revenue': 0.0,
          'views': 0,
        },
      };

      if (mounted) {
        setState(() {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isSeller) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Analytics'),
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
                  onRetry: _loadAnalyticsData,
                  icon: Icons.refresh,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview cards
                      const Text(
                        'Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Products',
                              _totalProducts.toString(),
                              Icons.inventory,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Orders',
                              _totalOrders.toString(),
                              Icons.shopping_cart,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Revenue',
                              '\$${_totalRevenue.toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Views',
                              _totalViews.toString(),
                              Icons.visibility,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Monthly comparison
                      const Text(
                        'Monthly Performance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassyContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildMonthlyComparison(
                                'This Month',
                                _monthlyStats['thisMonth'],
                              ),
                              const SizedBox(height: 16),
                              _buildMonthlyComparison(
                                'Last Month',
                                _monthlyStats['lastMonth'],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Performance insights
                      const Text(
                        'Performance Insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassyContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInsight(
                                'Conversion Rate',
                                '0.0%',
                                'Track how many views convert to sales',
                                Icons.trending_up,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildInsight(
                                'Average Order Value',
                                _totalOrders > 0
                                    ? '\$${(_totalRevenue / _totalOrders).toStringAsFixed(2)}'
                                    : '\$0.00',
                                'Average revenue per order',
                                Icons.account_balance_wallet,
                                Colors.green,
                              ),
                              const SizedBox(height: 16),
                              _buildInsight(
                                'Product Performance',
                                'View Details',
                                'See which products sell best',
                                Icons.bar_chart,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyComparison(String period, Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: Text(
            period,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${data['orders']} orders',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '\$${data['revenue'].toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInsight(String title, String value, String description, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}