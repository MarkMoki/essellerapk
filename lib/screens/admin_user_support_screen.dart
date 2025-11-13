import 'package:flutter/material.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminUserSupportScreen extends StatefulWidget {
  const AdminUserSupportScreen({super.key});

  @override
  State<AdminUserSupportScreen> createState() => _AdminUserSupportScreenState();
}

class _AdminUserSupportScreenState extends State<AdminUserSupportScreen> {
  List<Map<String, dynamic>> _supportTickets = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadSupportTickets();
  }

  Future<void> _loadSupportTickets() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load support tickets (placeholder - would need support_tickets table)
      _supportTickets = [
        {
          'id': '1',
          'user_id': 'user1',
          'user_email': 'user1@example.com',
          'subject': 'Cannot complete purchase',
          'message': 'I\'m having trouble completing my purchase. The payment keeps failing.',
          'status': 'open',
          'priority': 'high',
          'category': 'payment',
          'created_at': DateTime.now().subtract(const Duration(hours: 2)),
          'last_updated': DateTime.now().subtract(const Duration(hours: 1)),
        },
        {
          'id': '2',
          'user_id': 'seller1',
          'user_email': 'seller1@example.com',
          'subject': 'Product approval delay',
          'message': 'My product has been pending approval for over a week.',
          'status': 'in_progress',
          'priority': 'medium',
          'category': 'seller',
          'created_at': DateTime.now().subtract(const Duration(days: 1)),
          'last_updated': DateTime.now().subtract(const Duration(hours: 12)),
        },
        {
          'id': '3',
          'user_id': 'user2',
          'user_email': 'user2@example.com',
          'subject': 'Wrong item delivered',
          'message': 'I received a different product than what I ordered.',
          'status': 'resolved',
          'priority': 'medium',
          'category': 'order',
          'created_at': DateTime.now().subtract(const Duration(days: 3)),
          'last_updated': DateTime.now().subtract(const Duration(days: 2)),
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

  List<Map<String, dynamic>> get _filteredTickets {
    if (_selectedStatus == 'all') return _supportTickets;
    return _supportTickets.where((ticket) => ticket['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'User Support'),
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
          loadingMessage: 'Loading support tickets...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Support Tickets',
                  message: _errorMessage,
                  onRetry: _loadSupportTickets,
                  icon: Icons.refresh,
                )
              : Column(
                  children: [
                    // Status filter
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusFilter('All', 'all'),
                            const SizedBox(width: 8),
                            _buildStatusFilter('Open', 'open'),
                            const SizedBox(width: 8),
                            _buildStatusFilter('In Progress', 'in_progress'),
                            const SizedBox(width: 8),
                            _buildStatusFilter('Resolved', 'resolved'),
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
                              'Total Tickets',
                              _supportTickets.length.toString(),
                              Icons.confirmation_number,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Open Tickets',
                              _supportTickets.where((t) => t['status'] == 'open').length.toString(),
                              Icons.warning,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tickets list
                    Expanded(
                      child: _filteredTickets.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.support_agent_outlined,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No support tickets found',
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
                              itemCount: _filteredTickets.length,
                              itemBuilder: (context, index) {
                                final ticket = _filteredTickets[index];
                                return _buildSupportTicketCard(ticket);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(String label, String status) {
    final isSelected = _selectedStatus == status;
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
          _selectedStatus = status;
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

  Widget _buildSupportTicketCard(Map<String, dynamic> ticket) {
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
                        ticket['subject'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket['user_email'],
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPriorityBadge(ticket['priority']),
                    const SizedBox(height: 4),
                    _buildStatusBadge(ticket['status']),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Message preview
            Text(
              ticket['message'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Ticket details
            Row(
              children: [
                Expanded(
                  child: _buildTicketDetail(
                    'Category',
                    ticket['category'],
                    Icons.category,
                  ),
                ),
                Expanded(
                  child: _buildTicketDetail(
                    'Created',
                    _formatDate(ticket['created_at']),
                    Icons.access_time,
                  ),
                ),
              ],
            ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToTicket(ticket),
                    icon: const Icon(Icons.reply),
                    label: const Text('Respond'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (ticket['status'] != 'resolved')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _resolveTicket(ticket),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Resolve'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.greenAccent),
                        foregroundColor: Colors.greenAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority) {
      case 'high':
        color = Colors.redAccent;
        label = 'High';
        break;
      case 'medium':
        color = Colors.orangeAccent;
        label = 'Medium';
        break;
      case 'low':
        color = Colors.greenAccent;
        label = 'Low';
        break;
      default:
        color = Colors.grey;
        label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.redAccent;
        label = 'Open';
        break;
      case 'in_progress':
        color = Colors.orangeAccent;
        label = 'In Progress';
        break;
      case 'resolved':
        color = Colors.greenAccent;
        label = 'Resolved';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildTicketDetail(String label, String value, IconData icon) {
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

  Future<void> _respondToTicket(Map<String, dynamic> ticket) async {
    final responseController = TextEditingController();

    final response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Respond to: ${ticket['subject']}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'From: ${ticket['user_email']}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: responseController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your response...',
                hintStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orangeAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(responseController.text),
            style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
            child: const Text('Send Response'),
          ),
        ],
      ),
    );

    if (response != null && response.isNotEmpty) {
      // Update ticket status to in_progress if it was open
      if (ticket['status'] == 'open') {
        setState(() {
          ticket['status'] = 'in_progress';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _resolveTicket(Map<String, dynamic> ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Resolve Ticket', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to mark this ticket as resolved?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        ticket['status'] = 'resolved';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket marked as resolved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}