import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../providers/auth_provider.dart';
import '../services/returns_service.dart';

class ReturnsScreen extends StatefulWidget {
  final String? orderId;

  const ReturnsScreen({super.key, this.orderId});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  List<Map<String, dynamic>> _returnRequests = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';
  final ReturnsService _returnsService = ReturnsService();

  final List<String> _filterOptions = [
    'all',
    'pending',
    'approved',
    'rejected',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadReturnRequests();
  }

  Future<void> _loadReturnRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final returnRequests = await _returnsService.getUserReturnRequests(
        authProvider.user!.id,
        status: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _returnRequests = returnRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load returns: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredReturns() {
    if (_selectedFilter == 'all') return _returnRequests;
    return _returnRequests.where((request) => request['status'] == _selectedFilter).toList();
  }

  void _startNewReturn() {
    Navigator.pushNamed(context, '/new-return');
  }

  @override
  Widget build(BuildContext context) {
    final filteredReturns = _getFilteredReturns();

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlassyAppBar(
        title: 'Returns & Refunds',
        actions: [
          IconButton(
            onPressed: _startNewReturn,
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'New Return Request',
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
        child: Column(
          children: [
            // Filter Chips
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        filter.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      selectedColor: Colors.blueAccent,
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Returns List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredReturns.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_return,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No return requests',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your return history will appear here',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              GlassyButton(
                                onPressed: _startNewReturn,
                                child: const Text(
                                  'Start New Return',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredReturns.length,
                          itemBuilder: (context, index) {
                            return _buildReturnCard(filteredReturns[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> returnRequest) {
    final status = returnRequest['status'] as String;
    final statusColor = _getStatusColor(status);

    return GlassyContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Return Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Return ${returnRequest['id']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Order ID and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order: ${returnRequest['order_id']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(DateTime.parse(returnRequest['created_at'])),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Return Reason
            Text(
              'Reason: ${returnRequest['reason']}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            // Items
            ...List<Map<String, dynamic>>.from(returnRequest['items']).map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white24,
                      ),
                      child: const Icon(
                        Icons.inventory,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product ID: ${item['product_id']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Qty: ${item['quantity']}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Refund Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Refund Amount:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$${(returnRequest['refund_amount'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _editReturnRequest(returnRequest),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Edit Request',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelReturnRequest(returnRequest),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ),
                ] else if (status == 'approved') ...[
                  Expanded(
                    child: GlassyButton(
                      onPressed: () => _trackRefund(returnRequest),
                      child: const Text(
                        'Track Refund',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewReturnDetails(returnRequest),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'approved':
        return Colors.blueAccent;
      case 'pending':
        return Colors.orangeAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _editReturnRequest(Map<String, dynamic> returnRequest) {
    // Navigate to edit return screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit return functionality coming soon')),
    );
  }

  void _cancelReturnRequest(Map<String, dynamic> returnRequest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Cancel Return Request', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this return request? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Request', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Note: In a real implementation, you'd have a method to delete/cancel return requests
        // For now, we'll just remove it from the local list
        setState(() {
          _returnRequests.remove(returnRequest);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Return request cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel return request: ${e.toString().replaceFirst('Exception: ', '')}')),
          );
        }
      }
    }
  }

  void _trackRefund(Map<String, dynamic> returnRequest) {
    // Navigate to refund tracking screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refund tracking coming soon')),
    );
  }

  void _viewReturnDetails(Map<String, dynamic> returnRequest) {
    // Navigate to return details screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return details coming soon')),
    );
  }
}