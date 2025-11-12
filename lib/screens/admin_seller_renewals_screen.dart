import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../constants.dart';

class AdminSellerRenewalsScreen extends StatefulWidget {
  const AdminSellerRenewalsScreen({super.key});

  @override
  State<AdminSellerRenewalsScreen> createState() => _AdminSellerRenewalsScreenState();
}

class _AdminSellerRenewalsScreenState extends State<AdminSellerRenewalsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _expiringSellers = [];
  List<Map<String, dynamic>> _expiredSellers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedTab = 'expiring';

  @override
  void initState() {
    super.initState();
    _loadRenewalData();
  }

  Future<void> _loadRenewalData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      // Load sellers expiring within 30 days
      final expiringResponse = await _supabase
          .from('sellers')
          .select('*, profiles(email)')
          .gte('expires_at', now.toIso8601String())
          .lte('expires_at', thirtyDaysFromNow.toIso8601String())
          .order('expires_at', ascending: true);

      _expiringSellers = List<Map<String, dynamic>>.from(expiringResponse);

      // Load expired sellers
      final expiredResponse = await _supabase
          .from('sellers')
          .select('*, profiles(email)')
          .lt('expires_at', now.toIso8601String())
          .order('expires_at', ascending: false);

      _expiredSellers = List<Map<String, dynamic>>.from(expiredResponse);

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
      appBar: const GlassyAppBar(title: 'Seller Renewals'),
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
          loadingMessage: 'Loading renewal data...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Renewal Data',
                  message: _errorMessage,
                  onRetry: _loadRenewalData,
                  icon: Icons.refresh,
                )
              : Column(
                  children: [
                    // Tab selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton('Expiring Soon', 'expiring', _expiringSellers.length),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTabButton('Expired', 'expired', _expiredSellers.length),
                          ),
                        ],
                      ),
                    ),

                    // Content area
                    Expanded(
                      child: _selectedTab == 'expiring'
                          ? _buildExpiringSellersList()
                          : _buildExpiredSellersList(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tab, int count) {
    final isSelected = _selectedTab == tab;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.orangeAccent
            : Colors.white.withValues(alpha: 0.1),
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringSellersList() {
    if (_expiringSellers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No sellers expiring soon',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expiringSellers.length,
      itemBuilder: (context, index) {
        final seller = _expiringSellers[index];
        return _buildRenewalCard(seller, isExpired: false);
      },
    );
  }

  Widget _buildExpiredSellersList() {
    if (_expiredSellers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No expired sellers',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expiredSellers.length,
      itemBuilder: (context, index) {
        final seller = _expiredSellers[index];
        return _buildRenewalCard(seller, isExpired: true);
      },
    );
  }

  Widget _buildRenewalCard(Map<String, dynamic> seller, {required bool isExpired}) {
    final expiresAt = DateTime.parse(seller['expires_at']);
    final daysUntilExpiry = isExpired
        ? expiresAt.difference(DateTime.now()).inDays.abs()
        : expiresAt.difference(DateTime.now()).inDays;

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
                _buildUrgencyBadge(isExpired, daysUntilExpiry),
              ],
            ),

            const SizedBox(height: 12),

            // Expiry information
            Row(
              children: [
                Icon(
                  isExpired ? Icons.warning : Icons.schedule,
                  color: isExpired ? Colors.redAccent : Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpired
                        ? 'Expired $daysUntilExpiry days ago'
                        : 'Expires in $daysUntilExpiry days',
                    style: TextStyle(
                      color: isExpired ? Colors.redAccent : Colors.orangeAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Expiry Date: ${_formatDate(expiresAt)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _renewSeller(seller),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renew'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactSeller(seller),
                    icon: const Icon(Icons.email),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),

            if (isExpired) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This seller account is currently suspended. Renewal required to restore access.',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(bool isExpired, int days) {
    Color color;
    String text;

    if (isExpired) {
      color = Colors.redAccent;
      text = 'Expired';
    } else if (days <= 7) {
      color = Colors.redAccent;
      text = 'Urgent';
    } else if (days <= 14) {
      color = Colors.orangeAccent;
      text = 'Soon';
    } else {
      color = Colors.yellowAccent;
      text = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _renewSeller(Map<String, dynamic> seller) async {
    final newExpiryDate = DateTime.now().add(const Duration(days: 365)); // 1 year renewal

    try {
      await _supabase
          .from('sellers')
          .update({'expires_at': newExpiryDate.toIso8601String()})
          .eq('id', seller['id']);

      await _loadRenewalData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seller ${seller['profiles']?['email']} renewed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _contactSeller(Map<String, dynamic> seller) {
    // Placeholder for contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contacting ${seller['profiles']?['email']}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}