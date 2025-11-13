import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminUserActivityScreen extends StatefulWidget {
  const AdminUserActivityScreen({super.key});

  @override
  State<AdminUserActivityScreen> createState() => _AdminUserActivityScreenState();
}

class _AdminUserActivityScreenState extends State<AdminUserActivityScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _userActivities = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedPeriod = '24h';

  // Activity summary
  Map<String, dynamic> _activitySummary = {};

  @override
  void initState() {
    super.initState();
    _loadUserActivities();
  }

  Future<void> _loadUserActivities() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Calculate date range based on selected period
      final now = DateTime.now();
      DateTime startDate;
      switch (_selectedPeriod) {
        case '24h':
          startDate = now.subtract(const Duration(hours: 24));
          break;
        case '7d':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30d':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '90d':
          startDate = now.subtract(const Duration(days: 90));
          break;
        default:
          startDate = now.subtract(const Duration(hours: 24));
      }

      // Load user activities from database
      final response = await _supabase
          .from('activity_logs')
          .select('*, profiles(email)')
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: false);

      _userActivities = response.map((activity) {
        return {
          'id': activity['id'],
          'user_id': activity['user_id'],
          'user_email': activity['profiles']?['email'] ?? 'Unknown',
          'action': activity['action'],
          'description': activity['description'],
          'ip_address': activity['ip_address'] ?? 'Unknown',
          'user_agent': activity['user_agent'] ?? 'Unknown',
          'timestamp': DateTime.parse(activity['created_at']),
          'location': activity['location'] ?? 'Unknown',
        };
      }).toList();

      // Calculate activity summary
      final logins = _userActivities.where((a) => a['action'] == 'login').length;
      final orders = _userActivities.where((a) => a['action'] == 'order_placed').length;
      final products = _userActivities.where((a) => a['action'] == 'product_added').length;
      final security = _userActivities.where((a) => a['action'].contains('password') || a['action'].contains('suspended')).length;

      _activitySummary = {
        'total_activities': _userActivities.length,
        'unique_users': _userActivities.map((a) => a['user_id']).toSet().length,
        'logins': logins,
        'orders': orders,
        'products_added': products,
        'security_events': security,
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
    if (!authProvider.isAdmin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'User Activity'),
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
          loadingMessage: 'Loading user activities...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load User Activities',
                  message: _errorMessage,
                  onRetry: _loadUserActivities,
                  icon: Icons.refresh,
                )
              : Column(
                  children: [
                    // Period selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPeriodButton('24 Hours', '24h'),
                            const SizedBox(width: 8),
                            _buildPeriodButton('7 Days', '7d'),
                            const SizedBox(width: 8),
                            _buildPeriodButton('30 Days', '30d'),
                            const SizedBox(width: 8),
                            _buildPeriodButton('90 Days', '90d'),
                          ],
                        ),
                      ),
                    ),

                    // Activity summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Total Activities',
                                  _activitySummary['total_activities']?.toString() ?? '0',
                                  Icons.analytics,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Active Users',
                                  _activitySummary['unique_users']?.toString() ?? '0',
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
                                child: _buildSummaryCard(
                                  'Logins',
                                  _activitySummary['logins']?.toString() ?? '0',
                                  Icons.login,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Orders',
                                  _activitySummary['orders']?.toString() ?? '0',
                                  Icons.shopping_cart,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Activity list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _userActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _userActivities[index];
                          return _buildActivityCard(activity);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
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

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildActivityCard(Map<String, dynamic> activity) {
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
                        activity['user_email'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAction(activity['action']),
                        style: TextStyle(
                          color: _getActionColor(activity['action']),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(activity['timestamp']),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              activity['description'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            // Additional details
            Row(
              children: [
                Expanded(
                  child: _buildActivityDetail(
                    'IP Address',
                    activity['ip_address'],
                    Icons.wifi,
                  ),
                ),
                Expanded(
                  child: _buildActivityDetail(
                    'Location',
                    activity['location'],
                    Icons.location_on,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Device: ${activity['user_agent']}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),

            // Action button for suspicious activities
            if (_isSuspiciousActivity(activity['action']))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _investigateActivity(activity),
                        icon: const Icon(Icons.search),
                        label: const Text('Investigate'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                        ),
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

  Widget _buildActivityDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white60,
          size: 14,
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

  String _formatAction(String action) {
    switch (action) {
      case 'login':
        return 'User Login';
      case 'product_added':
        return 'Product Added';
      case 'order_placed':
        return 'Order Placed';
      case 'password_changed':
        return 'Password Changed';
      case 'user_suspended':
        return 'User Suspended';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.greenAccent;
      case 'product_added':
        return Colors.blueAccent;
      case 'order_placed':
        return Colors.orangeAccent;
      case 'password_changed':
        return Colors.purpleAccent;
      case 'user_suspended':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  bool _isSuspiciousActivity(String action) {
    return action == 'password_changed' || action == 'user_suspended';
  }

  void _investigateActivity(Map<String, dynamic> activity) {
    // Placeholder for investigation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Investigating activity: ${activity['description']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}