import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({super.key});

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends State<AdminSellersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  Future<void> _loadSellers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load sellers with user information
      final sellersResponse = await _supabase
          .from('sellers')
          .select('*, profiles(email, role)')
          .order('created_at', ascending: false);

      _sellers = List<Map<String, dynamic>>.from(sellersResponse);

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

  List<Map<String, dynamic>> get _filteredSellers {
    if (_selectedFilter == 'all') return _sellers;
    if (_selectedFilter == 'active') {
      return _sellers.where((seller) {
        final expiresAt = DateTime.parse(seller['expires_at']);
        return DateTime.now().isBefore(expiresAt);
      }).toList();
    }
    if (_selectedFilter == 'expired') {
      return _sellers.where((seller) {
        final expiresAt = DateTime.parse(seller['expires_at']);
        return DateTime.now().isAfter(expiresAt);
      }).toList();
    }
    return _sellers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Seller Management'),
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
          loadingMessage: 'Loading sellers...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Sellers',
                  message: _errorMessage,
                  onRetry: _loadSellers,
                  icon: Icons.refresh,
                )
              : Column(
                  children: [
                    // Filter tabs
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Active', 'active'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Expired', 'expired'),
                          ],
                        ),
                      ),
                    ),

                    // Stats overview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Sellers',
                              _sellers.length.toString(),
                              Icons.store,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Active Sellers',
                              _sellers.where((seller) {
                                final expiresAt = DateTime.parse(seller['expires_at']);
                                return DateTime.now().isBefore(expiresAt);
                              }).length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sellers list
                    Expanded(
                      child: _filteredSellers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.store_outlined,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No sellers found',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSellers.length,
                              itemBuilder: (context, index) {
                                final seller = _filteredSellers[index];
                                return _buildSellerCard(seller);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;
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
          _selectedFilter = filter;
        });
      },
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      selectedColor: Colors.orangeAccent.withValues(alpha: 0.3),
      checkmarkColor: Colors.orangeAccent,
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

  Widget _buildSellerCard(Map<String, dynamic> seller) {
    final expiresAt = DateTime.parse(seller['expires_at']);
    final isExpired = DateTime.now().isAfter(expiresAt);
    final daysUntilExpiry = expiresAt.difference(DateTime.now()).inDays;

    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${seller['id']}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isExpired),
              ],
            ),

            const SizedBox(height: 12),

            // Seller details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Expires',
                    _formatDate(expiresAt),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Days Left',
                    isExpired ? 'Expired' : daysUntilExpiry.toString(),
                    Icons.schedule,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Created',
                    _formatDate(DateTime.parse(seller['created_at'])),
                    Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Created By',
                    seller['created_by'],
                    Icons.person,
                  ),
                ),
              ],
            ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                if (isExpired) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _renewSeller(seller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Renew'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewSellerDetails(seller),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orangeAccent),
                      foregroundColor: Colors.orangeAccent,
                    ),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteSeller(seller),
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Delete Seller',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.redAccent : Colors.greenAccent,
        ),
      ),
      child: Text(
        isExpired ? 'Expired' : 'Active',
        style: TextStyle(
          color: isExpired ? Colors.redAccent : Colors.greenAccent,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _renewSeller(Map<String, dynamic> seller) async {
    // Placeholder for renewal logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Renewal for ${seller['profiles']?['email']} initiated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewSellerDetails(Map<String, dynamic> seller) {
    // Placeholder for details view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seller details view - Coming soon')),
    );
  }

  Future<void> _deleteSeller(Map<String, dynamic> seller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Delete Seller', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete seller ${seller['profiles']?['email']}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('sellers').delete().eq('id', seller['id']);
        await _loadSellers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete seller: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}