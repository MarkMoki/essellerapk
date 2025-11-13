import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../widgets/professional_image.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/access_denied_screen.dart';
import '../constants.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Product> _products = [];
  List<Order> _recentOrders = [];
  int _totalUsers = 0;
  double _totalRevenue = 0.0;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load all data concurrently
      final results = await Future.wait([
        _productService.fetchProducts(),
        _orderService.fetchAllOrders(),
        _supabase.from('profiles').select('id'),
        _supabase.from('orders').select('total_amount, status'),
      ]);

      final products = results[0] as List<Product>;
      final orders = results[1] as List<Order>;
      final usersResponse = results[2] as List<dynamic>;
      final revenueResponse = results[3] as List<dynamic>;

      // Calculate revenue
      double totalRevenue = 0.0;
      for (final order in revenueResponse) {
        final status = order['status'];
        final amount = order['total_amount'] as num?;
        if (status == 'paid' || status == 'shipped' || status == 'delivered') {
          totalRevenue += amount?.toDouble() ?? 0.0;
        }
      }

      // Get recent orders (last 5)
      final recentOrders = orders.take(5).toList();

      if (mounted) {
        setState(() {
          _products = products;
          _recentOrders = recentOrders;
          _totalUsers = usersResponse.length;
          _totalRevenue = totalRevenue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadDashboardData,
            ),
          ),
        );
      }
    }
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.teal;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                // Navigation will be handled by AuthWrapper
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildProductsScreen();
      case 2:
        return const AdminOrdersScreen();
      case 3:
        return const AdminUsersScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overview Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewCard(
                        'Total Products',
                        _products.length.toString(),
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOverviewCard(
                        'Total Users',
                        _totalUsers.toString(),
                        Icons.people,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewCard(
                        'Total Revenue',
                        'Ksh${_totalRevenue.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOverviewCard(
                        'Recent Orders',
                        _recentOrders.length.toString(),
                        Icons.shopping_cart,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Actions
                GlassyContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlassyButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                                ).then((_) => _loadDashboardData());
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Add Product'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassyButton(
                              onPressed: () {
                                setState(() {
                                  _currentIndex = 2; // Switch to orders tab
                                });
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('View Orders'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Orders Section
                if (_recentOrders.isNotEmpty) ...[
                  const Text(
                    'Recent Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._recentOrders.map((order) => GlassyContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order.id.substring(0, 8)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.status.displayName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: Ksh${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                ],

                // Products Preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Products',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1; // Switch to products tab
                        });
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._products.take(3).map((product) => GlassyContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ProfessionalImage(
                        imageUrl: product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Ksh${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Stock: ${product.stock}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProductScreen(product: product),
                                ),
                              ).then((_) => _loadDashboardData());
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              await _productService.deleteProduct(product.id, authProvider);
                              _loadDashboardData();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
  }

  Widget _buildProductsScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return GlassyContainer(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              ProfessionalImage(
                imageUrl: product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Ksh${product.price}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Stock: ${product.stock}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProductScreen(product: product),
                        ),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await _productService.deleteProduct(product.id, authProvider);
                      _loadDashboardData();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlassyAppBar(
        title: 'Admin Panel',
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
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
        child: getCurrentScreen(),
      ),
      bottomNavigationBar: GlassyBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        isAdmin: true,
      ),
    );
  }
}