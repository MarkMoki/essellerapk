import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminSellerPerformanceScreen extends StatefulWidget {
  const AdminSellerPerformanceScreen({super.key});

  @override
  State<AdminSellerPerformanceScreen> createState() => _AdminSellerPerformanceScreenState();
}

class _AdminSellerPerformanceScreenState extends State<AdminSellerPerformanceScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _sellerPerformance = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _sortBy = 'revenue';

  @override
  void initState() {
    super.initState();
    _loadSellerPerformance();
  }

  Future<void> _loadSellerPerformance() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load sellers with performance metrics (placeholder data)
      final sellersResponse = await _supabase
          .from('sellers')
          .select('*, profiles(email)')
          .order('created_at', ascending: false);

      final sellers = List<Map<String, dynamic>>.from(sellersResponse);

      // Calculate performance metrics for each seller (placeholder)
      _sellerPerformance = sellers.map((seller) {
        final performance = {
          ...seller,
          'total_orders': (seller['id'].hashCode % 100) + 10, // Placeholder
          'total_revenue': ((seller['id'].hashCode % 1000) + 100) * 10.0, // Placeholder
          'average_rating': 3.5 + (seller['id'].hashCode % 15) / 10.0, // Placeholder
          'total_products': (seller['id'].hashCode % 50) + 5, // Placeholder
          'conversion_rate': 2.0 + (seller['id'].hashCode % 8) / 10.0, // Placeholder
        };
        return performance;
      }).toList();

      _sortPerformance();

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

  void _sortPerformance() {
    _sellerPerformance.sort((a, b) {
      switch (_sortBy) {
        case 'revenue':
          return (b['total_revenue'] as double).compareTo(a['total_revenue'] as double);
        case 'orders':
          return (b['total_orders'] as int).compareTo(a['total_orders'] as int);
        case 'rating':
          return (b['average_rating'] as double).compareTo(a['average_rating'] as double);
        case 'products':
          return (b['total_products'] as int).compareTo(a['total_products'] as int);
        default:
          return 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Seller Performance'),
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
          loadingMessage: 'Loading performance data...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Performance Data',
                  message: _errorMessage,
                  onRetry: _loadSellerPerformance,
                  icon: Icons.refresh,
                )
              : Column(
                  children: [
                    // Sort options
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Sort by:',
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
                                  _buildSortButton('Revenue', 'revenue'),
                                  const SizedBox(width: 8),
                                  _buildSortButton('Orders', 'orders'),
                                  const SizedBox(width: 8),
                                  _buildSortButton('Rating', 'rating'),
                                  const SizedBox(width: 8),
                                  _buildSortButton('Products', 'products'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Performance list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sellerPerformance.length,
                        itemBuilder: (context, index) {
                          final seller = _sellerPerformance[index];
                          return _buildPerformanceCard(seller, index + 1);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String sortBy) {
    final isSelected = _sortBy == sortBy;
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
          _sortBy = sortBy;
          _sortPerformance();
        });
      },
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      selectedColor: Colors.orangeAccent.withValues(alpha: 0.3),
      checkmarkColor: Colors.orangeAccent,
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> seller, int rank) {
    final isExpired = DateTime.now().isAfter(DateTime.parse(seller['expires_at']));

    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rank
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankColor(rank),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seller['profiles']?['email'] ?? 'Unknown Seller',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isExpired ? 'Expired' : 'Active',
                            style: TextStyle(
                              color: isExpired ? Colors.redAccent : Colors.greenAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _viewSellerDetails(seller),
                  icon: const Icon(Icons.visibility, color: Colors.white70),
                  tooltip: 'View Details',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Performance metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Revenue',
                    '\$${seller['total_revenue'].toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Orders',
                    seller['total_orders'].toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Rating',
                    seller['average_rating'].toStringAsFixed(1),
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Products',
                    seller['total_products'].toString(),
                    Icons.inventory,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Conversion',
                    '${seller['conversion_rate'].toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.teal,
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.yellow;
    if (rank == 2) return Colors.grey;
    if (rank == 3) return Colors.orange;
    return Colors.white.withValues(alpha: 0.3);
  }

  void _viewSellerDetails(Map<String, dynamic> seller) {
    // Placeholder for detailed view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${seller['profiles']?['email']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}