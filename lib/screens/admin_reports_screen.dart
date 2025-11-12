import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedPeriod = '30d';

  // Report data
  Map<String, dynamic> _salesReport = {};
  Map<String, dynamic> _userReport = {};
  Map<String, dynamic> _productReport = {};
  Map<String, dynamic> _financialReport = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load sales report
      final ordersResponse = await _supabase
          .from('orders')
          .select('total_amount, status, created_at');

      final orders = List<Map<String, dynamic>>.from(ordersResponse);
      final completedOrders = orders.where((order) => order['status'] == 'delivered');

      _salesReport = {
        'total_orders': orders.length,
        'completed_orders': completedOrders.length,
        'total_revenue': completedOrders.fold<double>(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble()),
        'average_order_value': completedOrders.isNotEmpty
            ? completedOrders.fold<double>(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble()) / completedOrders.length
            : 0.0,
      };

      // Load user report
      final usersResponse = await _supabase
          .from('profiles')
          .select('role, created_at');

      final users = List<Map<String, dynamic>>.from(usersResponse);
      _userReport = {
        'total_users': users.length,
        'admin_users': users.where((user) => user['role'] == 'admin').length,
        'seller_users': users.where((user) => user['role'] == 'seller').length,
        'regular_users': users.where((user) => user['role'] == 'user').length,
      };

      // Load product report
      final productsResponse = await _supabase
          .from('products')
          .select('id, stock, created_at');

      final products = List<Map<String, dynamic>>.from(productsResponse);
      _productReport = {
        'total_products': products.length,
        'in_stock_products': products.where((product) => (product['stock'] as int) > 0).length,
        'out_of_stock_products': products.where((product) => (product['stock'] as int) == 0).length,
        'low_stock_products': products.where((product) => (product['stock'] as int) > 0 && (product['stock'] as int) <= 5).length,
      };

      // Financial report (placeholder)
      _financialReport = {
        'total_revenue': _salesReport['total_revenue'],
        'platform_fees': (_salesReport['total_revenue'] as double) * 0.05,
        'seller_payouts': (_salesReport['total_revenue'] as double) * 0.95,
        'pending_payouts': 1250.00,
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
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Reports'),
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
          loadingMessage: 'Loading reports...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Reports',
                  message: _errorMessage,
                  onRetry: _loadReports,
                  icon: Icons.refresh,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      Row(
                        children: [
                          const Text(
                            'Report Period:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildPeriodButton('7d', '7 Days'),
                                  const SizedBox(width: 8),
                                  _buildPeriodButton('30d', '30 Days'),
                                  const SizedBox(width: 8),
                                  _buildPeriodButton('90d', '90 Days'),
                                  const SizedBox(width: 8),
                                  _buildPeriodButton('1y', '1 Year'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Sales Report
                      const Text(
                        'Sales Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassyContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildReportMetric(
                                'Total Orders',
                                _salesReport['total_orders']?.toString() ?? '0',
                                Icons.shopping_cart,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Completed Orders',
                                _salesReport['completed_orders']?.toString() ?? '0',
                                Icons.check_circle,
                                Colors.green,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Total Revenue',
                                '\$${_salesReport['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                                Icons.attach_money,
                                Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Average Order Value',
                                '\$${_salesReport['average_order_value']?.toStringAsFixed(2) ?? '0.00'}',
                                Icons.trending_up,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // User Report
                      const Text(
                        'User Statistics',
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
                              _buildReportMetric(
                                'Total Users',
                                _userReport['total_users']?.toString() ?? '0',
                                Icons.people,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Admin Users',
                                _userReport['admin_users']?.toString() ?? '0',
                                Icons.admin_panel_settings,
                                Colors.red,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Seller Users',
                                _userReport['seller_users']?.toString() ?? '0',
                                Icons.store,
                                Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Regular Users',
                                _userReport['regular_users']?.toString() ?? '0',
                                Icons.person,
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Product Report
                      const Text(
                        'Product Statistics',
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
                              _buildReportMetric(
                                'Total Products',
                                _productReport['total_products']?.toString() ?? '0',
                                Icons.inventory,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'In Stock',
                                _productReport['in_stock_products']?.toString() ?? '0',
                                Icons.check_circle,
                                Colors.green,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Out of Stock',
                                _productReport['out_of_stock_products']?.toString() ?? '0',
                                Icons.cancel,
                                Colors.red,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Low Stock (≤5)',
                                _productReport['low_stock_products']?.toString() ?? '0',
                                Icons.warning,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Financial Report
                      const Text(
                        'Financial Overview',
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
                              _buildReportMetric(
                                'Total Revenue',
                                '\$${_financialReport['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                                Icons.attach_money,
                                Colors.green,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Platform Fees (5%)',
                                '\$${_financialReport['platform_fees']?.toStringAsFixed(2) ?? '0.00'}',
                                Icons.account_balance,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Seller Payouts',
                                '\$${_financialReport['seller_payouts']?.toStringAsFixed(2) ?? '0.00'}',
                                Icons.payment,
                                Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              _buildReportMetric(
                                'Pending Payouts',
                                '\$${_financialReport['pending_payouts']?.toStringAsFixed(2) ?? '0.00'}',
                                Icons.schedule,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Export button
                      ElevatedButton.icon(
                        onPressed: _exportReports,
                        icon: const Icon(Icons.download),
                        label: const Text('Export Reports'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = period;
        });
        // In a real app, this would reload data for the selected period
      },
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      selectedColor: Colors.orangeAccent.withValues(alpha: 0.3),
      checkmarkColor: Colors.orangeAccent,
    );
  }

  Widget _buildReportMetric(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _exportReports() {
    // Placeholder for export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report export functionality - Coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}