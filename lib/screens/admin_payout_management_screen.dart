import 'package:flutter/material.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminPayoutManagementScreen extends StatefulWidget {
  const AdminPayoutManagementScreen({super.key});

  @override
  State<AdminPayoutManagementScreen> createState() => _AdminPayoutManagementScreenState();
}

class _AdminPayoutManagementScreenState extends State<AdminPayoutManagementScreen> {
  // final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingPayouts = [];
  List<Map<String, dynamic>> _completedPayouts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadPayoutData();
  }

  Future<void> _loadPayoutData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load pending payouts (placeholder - would need payouts table)
      _pendingPayouts = [
        {
          'id': '1',
          'seller_id': 'seller1',
          'seller_email': 'seller1@example.com',
          'amount': 450.00,
          'method': 'M-Pesa',
          'account_details': '+254712345678',
          'requested_at': DateTime.now().subtract(const Duration(days: 2)),
          'status': 'pending',
        },
        {
          'id': '2',
          'seller_id': 'seller2',
          'seller_email': 'seller2@example.com',
          'amount': 320.50,
          'method': 'Bank Transfer',
          'account_details': 'KBZ Bank - 1234567890',
          'requested_at': DateTime.now().subtract(const Duration(days: 1)),
          'status': 'pending',
        },
      ];

      // Load completed payouts (placeholder)
      _completedPayouts = [
        {
          'id': '3',
          'seller_id': 'seller3',
          'seller_email': 'seller3@example.com',
          'amount': 280.00,
          'method': 'M-Pesa',
          'account_details': '+254798765432',
          'requested_at': DateTime.now().subtract(const Duration(days: 7)),
          'processed_at': DateTime.now().subtract(const Duration(days: 6)),
          'status': 'completed',
          'reference': 'REF001',
        },
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
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Payout Management'),
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
          loadingMessage: 'Loading payout data...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Payout Data',
                  message: _errorMessage,
                  onRetry: _loadPayoutData,
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
                            child: _buildTabButton('Pending', 'pending', _pendingPayouts.length),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTabButton('Completed', 'completed', _completedPayouts.length),
                          ),
                        ],
                      ),
                    ),

                    // Content area
                    Expanded(
                      child: _selectedTab == 'pending'
                          ? _buildPendingPayoutsList()
                          : _buildCompletedPayoutsList(),
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

  Widget _buildPendingPayoutsList() {
    if (_pendingPayouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending payouts',
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
      itemCount: _pendingPayouts.length,
      itemBuilder: (context, index) {
        final payout = _pendingPayouts[index];
        return _buildPayoutCard(payout, isPending: true);
      },
    );
  }

  Widget _buildCompletedPayoutsList() {
    if (_completedPayouts.isEmpty) {
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
              'No completed payouts',
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
      itemCount: _completedPayouts.length,
      itemBuilder: (context, index) {
        final payout = _completedPayouts[index];
        return _buildPayoutCard(payout, isPending: false);
      },
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> payout, {required bool isPending}) {
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
                        payout['seller_email'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${payout['seller_id']}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(payout['status']),
              ],
            ),

            const SizedBox(height: 12),

            // Payout details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Amount',
                    '\$${payout['amount'].toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Method',
                    payout['method'],
                    Icons.payment,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Account: ${payout['account_details']}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Requested: ${_formatDate(payout['requested_at'])}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),

            if (!isPending && payout['processed_at'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Processed: ${_formatDate(payout['processed_at'])}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                ),
              ),
            ],

            if (!isPending && payout['reference'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ref: ${payout['reference']}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _processPayout(payout),
                      icon: const Icon(Icons.check),
                      label: const Text('Process'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectPayout(payout),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewPayoutDetails(payout),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blueAccent),
                        foregroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orangeAccent;
        label = 'Pending';
        break;
      case 'completed':
        color = Colors.greenAccent;
        label = 'Completed';
        break;
      case 'rejected':
        color = Colors.redAccent;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
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
                  fontSize: 14,
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

  Future<void> _processPayout(Map<String, dynamic> payout) async {
    // Placeholder for payout processing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing payout of \$${payout['amount']} to ${payout['seller_email']}'),
        backgroundColor: Colors.blue,
      ),
    );

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Update payout status (placeholder)
    setState(() {
      payout['status'] = 'completed';
      payout['processed_at'] = DateTime.now();
      payout['reference'] = 'REF${DateTime.now().millisecondsSinceEpoch}';
      _completedPayouts.insert(0, payout);
      _pendingPayouts.remove(payout);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout processed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectPayout(Map<String, dynamic> payout) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Reject Payout', style: TextStyle(color: Colors.white)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Reason for rejection...',
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('Payment method verification failed'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null) {
      setState(() {
        payout['status'] = 'rejected';
        payout['rejection_reason'] = reason;
        _pendingPayouts.remove(payout);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewPayoutDetails(Map<String, dynamic> payout) {
    // Placeholder for details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for payout ${payout['id']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}