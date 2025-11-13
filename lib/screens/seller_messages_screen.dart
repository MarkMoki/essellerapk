import 'package:flutter/material.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SellerMessagesScreen extends StatefulWidget {
  const SellerMessagesScreen({super.key});

  @override
  State<SellerMessagesScreen> createState() => _SellerMessagesScreenState();
}

class _SellerMessagesScreenState extends State<SellerMessagesScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // final sellerId = 'placeholder'; // authProvider.user!.id;

      // Load messages (placeholder - would need messages table)
      _messages = [
        {
          'id': '1',
          'sender': 'John Doe',
          'subject': 'Question about product availability',
          'message': 'Hi, I was wondering if you have this product in stock...',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'is_read': false,
          'type': 'customer_inquiry',
        },
        {
          'id': '2',
          'sender': 'Admin',
          'subject': 'Account verification required',
          'message': 'Please verify your account details to continue selling...',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'is_read': true,
          'type': 'admin_notification',
        },
        {
          'id': '3',
          'sender': 'Jane Smith',
          'subject': 'Order #123456 status update',
          'message': 'Your order has been shipped and is on its way...',
          'timestamp': DateTime.now().subtract(const Duration(days: 3)),
          'is_read': true,
          'type': 'order_update',
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

  List<Map<String, dynamic>> get _filteredMessages {
    if (_selectedFilter == 'all') return _messages;
    if (_selectedFilter == 'unread') return _messages.where((msg) => !msg['is_read']).toList();
    return _messages.where((msg) => msg['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isSeller) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Messages'),
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
          loadingMessage: 'Loading messages...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Messages',
                  message: _errorMessage,
                  onRetry: _loadMessages,
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
                            _buildFilterChip('Unread', 'unread'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Customer', 'customer_inquiry'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Admin', 'admin_notification'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Orders', 'order_update'),
                          ],
                        ),
                      ),
                    ),

                    // Messages list
                    Expanded(
                      child: _filteredMessages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mail_outline,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages found',
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
                              itemCount: _filteredMessages.length,
                              itemBuilder: (context, index) {
                                final message = _filteredMessages[index];
                                return _buildMessageCard(message);
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

  Widget _buildMessageCard(Map<String, dynamic> message) {
    return GlassyContainer(
      child: InkWell(
        onTap: () => _openMessage(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getMessageColor(message['type']),
                child: Icon(
                  _getMessageIcon(message['type']),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message['sender'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: message['is_read'] ? FontWeight.normal : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!message['is_read'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message['subject'],
                      style: TextStyle(
                        color: message['is_read'] ? Colors.white70 : Colors.white,
                        fontSize: 14,
                        fontWeight: message['is_read'] ? FontWeight.normal : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message['message'],
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Timestamp
              Text(
                _formatTime(message['timestamp']),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMessageColor(String type) {
    switch (type) {
      case 'customer_inquiry':
        return Colors.blueAccent;
      case 'admin_notification':
        return Colors.orangeAccent;
      case 'order_update':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getMessageIcon(String type) {
    switch (type) {
      case 'customer_inquiry':
        return Icons.person;
      case 'admin_notification':
        return Icons.admin_panel_settings;
      case 'order_update':
        return Icons.shopping_cart;
      default:
        return Icons.mail;
    }
  }

  void _openMessage(Map<String, dynamic> message) {
    // Mark as read
    setState(() {
      message['is_read'] = true;
    });

    // Show message dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          message['subject'],
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From: ${message['sender']}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              message['message'],
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatDateTime(message['timestamp'])}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _replyToMessage(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _replyToMessage(Map<String, dynamic> message) {
    // Placeholder for reply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reply to ${message['sender']} - Feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _formatDateTime(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}