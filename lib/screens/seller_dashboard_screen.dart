import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../models/seller.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Seller? _seller;
  int _productCount = 0;
  double _totalRevenue = 0.0;
  int _orderCount = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final seller = await authProvider.getSellerInfo();

      if (seller == null) {
        throw Exception('Seller information not found');
      }

      _seller = seller;

      // Load product count
      final productsResponse = await _supabase
          .from('products')
          .select('id')
          .eq('seller_id', authProvider.user!.id);

      _productCount = productsResponse.length;

      // Load total revenue from orders
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select('price, quantity')
          .eq('product_id', productsResponse.map((p) => p['id']).toList());

      double totalRevenue = 0.0;
      for (var item in orderItemsResponse) {
        totalRevenue += (item['price'] as num) * (item['quantity'] as int);
      }
      _totalRevenue = totalRevenue;

      // Load order count - count orders that contain seller's products
      final productIds = productsResponse.map((p) => p['id'] as String).toList();
      if (productIds.isNotEmpty) {
        final orderItemsForSeller = await _supabase
            .from('order_items')
            .select('order_id')
            .inFilter('product_id', productIds);

        final uniqueOrderIds = orderItemsForSeller.map((item) => item['order_id']).toSet();
        _orderCount = uniqueOrderIds.length;
      } else {
        _orderCount = 0;
      }

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
      appBar: const GlassyAppBar(title: 'Seller Dashboard'),
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
          loadingMessage: 'Loading dashboard...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Dashboard',
                  message: _errorMessage,
                  onRetry: _loadDashboardData,
                  icon: Icons.refresh,
                )
              : _seller == null
                  ? const Center(
                      child: Text(
                        'Seller information not available',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Seller status card
                          GlassyContainer(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _seller!.isExpired ? Icons.warning : Icons.store,
                                        color: _seller!.isExpired ? Colors.redAccent : Colors.orangeAccent,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _seller!.isExpired ? 'Account Expired' : 'Active Seller',
                                              style: TextStyle(
                                                color: _seller!.isExpired ? Colors.redAccent : Colors.orangeAccent,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _seller!.isExpired
                                                  ? 'Your seller account has expired. Contact admin to renew.'
                                                  : 'Expires: ${_formatDate(_seller!.expiresAt)}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Stats cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Products',
                                  _productCount.toString(),
                                  Icons.inventory,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Revenue',
                                  '\$${_totalRevenue.toStringAsFixed(2)}',
                                  Icons.attach_money,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Days Left',
                                  _seller!.timeUntilExpiration.inDays.toString(),
                                  Icons.schedule,
                                  _seller!.isExpired ? Colors.red : Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Orders',
                                  _orderCount.toString(),
                                  Icons.shopping_cart,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Quick actions
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_seller!.isExpired)
                            // Show renewal message for expired sellers
                            GlassyContainer(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.lock,
                                      color: Colors.redAccent,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Account Suspended',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Your seller account has expired. Please contact an administrator to renew your account and regain access to seller features.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            // Show actions for active sellers
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        'Add Product',
                                        Icons.add,
                                        Colors.blue,
                                        () {
                                          Navigator.pushNamed(context, '/seller/add-product');
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildActionButton(
                                        'My Products',
                                        Icons.inventory,
                                        Colors.green,
                                        () {
                                          Navigator.pushNamed(context, '/seller/products');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        'Payment Methods',
                                        Icons.payment,
                                        Colors.orange,
                                        () {
                                          Navigator.pushNamed(context, '/seller/payment-methods');
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildActionButton(
                                        'Analytics',
                                        Icons.analytics,
                                        Colors.purple,
                                        () {
                                          Navigator.pushNamed(context, '/seller/analytics');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return GlassyContainer(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
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
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}