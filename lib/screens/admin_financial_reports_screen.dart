import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class AdminFinancialReportsScreen extends StatefulWidget {
  const AdminFinancialReportsScreen({super.key});

  @override
  State<AdminFinancialReportsScreen> createState() => _AdminFinancialReportsScreenState();
}

class _AdminFinancialReportsScreenState extends State<AdminFinancialReportsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedPeriod = '30d';

  // Financial data
  Map<String, dynamic> _revenueData = {};
  Map<String, dynamic> _expenseData = {};
  Map<String, dynamic> _profitData = {};
  List<Map<String, dynamic>> _monthlyTrends = [];

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load orders for revenue calculation
      final ordersResponse = await _supabase
          .from('orders')
          .select('total_amount, status, created_at');

      final orders = List<Map<String, dynamic>>.from(ordersResponse);
      final completedOrders = orders.where((order) => order['status'] == 'delivered');

      final totalRevenue = completedOrders.fold<double>(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());
      final platformFees = totalRevenue * 0.05; // 5% platform fee
      final sellerPayouts = totalRevenue * 0.95; // 95% to sellers

      _revenueData = {
        'total_revenue': totalRevenue,
        'platform_fees': platformFees,
        'seller_payouts': sellerPayouts,
        'net_platform_revenue': platformFees,
      };

      // Expense data (placeholder)
      _expenseData = {
        'server_costs': 2500.00,
        'payment_processing': totalRevenue * 0.02, // 2% payment processing
        'marketing': 1500.00,
        'support': 800.00,
        'total_expenses': 2500.00 + (totalRevenue * 0.02) + 1500.00 + 800.00,
      };

      // Profit calculation
      _profitData = {
        'gross_profit': _revenueData['net_platform_revenue'],
        'net_profit': _revenueData['net_platform_revenue'] - _expenseData['total_expenses'],
        'profit_margin': _revenueData['total_revenue'] > 0
            ? ((_revenueData['net_platform_revenue'] - _expenseData['total_expenses']) / _revenueData['total_revenue']) * 100
            : 0.0,
      };

      // Monthly trends (placeholder)
      _monthlyTrends = [
        {'month': 'Jan', 'revenue': 12500.00, 'expenses': 3200.00, 'profit': 9300.00},
        {'month': 'Feb', 'revenue': 15200.00, 'expenses': 3800.00, 'profit': 11400.00},
        {'month': 'Mar', 'revenue': 18700.00, 'expenses': 4200.00, 'profit': 14500.00},
        {'month': 'Apr', 'revenue': 22100.00, 'expenses': 4800.00, 'profit': 17300.00},
        {'month': 'May', 'revenue': 19800.00, 'expenses': 4500.00, 'profit': 15300.00},
        {'month': 'Jun', 'revenue': 24300.00, 'expenses': 5200.00, 'profit': 19100.00},
      ];

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
      appBar: const GlassyAppBar(title: 'Financial Reports'),
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
          loadingMessage: 'Loading financial data...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Financial Data',
                  message: _errorMessage,
                  onRetry: _loadFinancialData,
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
                            'Period:',
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

                      // Revenue Overview
                      const Text(
                        'Revenue Overview',
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
                            child: _buildFinancialCard(
                              'Total Revenue',
                              '\$${_revenueData['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFinancialCard(
                              'Platform Fees',
                              '\$${_revenueData['platform_fees']?.toStringAsFixed(2) ?? '0.00'}',
                              Icons.account_balance,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Profit & Loss
                      const Text(
                        'Profit & Loss',
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
                              _buildPLItem('Revenue', _revenueData['total_revenue'] ?? 0.0, Colors.green),
                              const SizedBox(height: 8),
                              _buildPLItem('Platform Fees', -(_revenueData['platform_fees'] ?? 0.0), Colors.red),
                              const SizedBox(height: 8),
                              _buildPLItem('Seller Payouts', -(_revenueData['seller_payouts'] ?? 0.0), Colors.red),
                              const Divider(color: Colors.white30, height: 16),
                              _buildPLItem('Gross Platform Revenue', _revenueData['net_platform_revenue'] ?? 0.0, Colors.green, isBold: true),
                              const SizedBox(height: 16),
                              _buildPLItem('Server Costs', -(_expenseData['server_costs'] ?? 0.0), Colors.red),
                              const SizedBox(height: 8),
                              _buildPLItem('Payment Processing', -(_expenseData['payment_processing'] ?? 0.0), Colors.red),
                              const SizedBox(height: 8),
                              _buildPLItem('Marketing', -(_expenseData['marketing'] ?? 0.0), Colors.red),
                              const SizedBox(height: 8),
                              _buildPLItem('Support', -(_expenseData['support'] ?? 0.0), Colors.red),
                              const Divider(color: Colors.white30, height: 16),
                              _buildPLItem('Net Profit', _profitData['net_profit'] ?? 0.0,
                                  (_profitData['net_profit'] ?? 0.0) >= 0 ? Colors.green : Colors.red, isBold: true),
                              const SizedBox(height: 8),
                              _buildPLItem('Profit Margin', _profitData['profit_margin'] ?? 0.0, Colors.blue, isPercentage: true, isBold: true),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Monthly Trends
                      const Text(
                        'Monthly Trends',
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
                            children: _monthlyTrends.map((trend) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        trend['month'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '\$${trend['revenue'].toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '\$${trend['expenses'].toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '\$${trend['profit'].toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Export button
                      ElevatedButton.icon(
                        onPressed: _exportFinancialReports,
                        icon: const Icon(Icons.download),
                        label: const Text('Export Financial Reports'),
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

  Widget _buildFinancialCard(String title, String value, IconData icon, Color color) {
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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

  Widget _buildPLItem(String label, double amount, Color color, {bool isBold = false, bool isPercentage = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          isPercentage
              ? '${amount.toStringAsFixed(1)}%'
              : '${amount >= 0 ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _exportFinancialReports() {
    // Placeholder for export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial report export functionality - Coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}