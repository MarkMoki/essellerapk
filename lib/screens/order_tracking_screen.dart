import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../providers/auth_provider.dart';
import '../services/order_tracking_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _trackingSteps = [];
  bool _isLoading = true;
  final OrderTrackingService _trackingService = OrderTrackingService();

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final trackingData = await _trackingService.getOrderTracking(
        widget.orderId,
        authProvider.user!.id,
      );

      if (mounted && trackingData != null) {
        setState(() {
          _orderData = trackingData['order'];
          _trackingSteps = List<Map<String, dynamic>>.from(trackingData['tracking_steps']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tracking data: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlassyAppBar(
        title: 'Track Order',
        actions: [
          IconButton(
            onPressed: () {
              // Refresh tracking info
              _loadOrderData();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    GlassyContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${widget.orderId}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildStatusBadge(_orderData!['status']),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_orderData!['carrier_info']?['estimatedDelivery'] != null)
                            Text(
                              'Estimated Delivery: ${_orderData!['carrier_info']['estimatedDelivery']}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.local_shipping, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_orderData!['carrier_info']?['carrier'] ?? 'Processing'} - Tracking: ${_orderData!['carrier_info']?['trackingNumber'] ?? 'Not available'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tracking Timeline
                    const Text(
                      'Tracking Updates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ..._trackingSteps.map((step) => _buildTrackingStep(step)),

                    const SizedBox(height: 20),

                    // Order Items
                    const Text(
                      'Order Items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GlassyContainer(
                      child: Column(
                        children: List<Map<String, dynamic>>.from(_orderData!['order_items'] ?? []).map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white24,
                                  ),
                                  child: const Icon(
                                    Icons.inventory,
                                    color: Colors.white54,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'] ?? 'Product',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${item['quantity']} × \$${item['price']}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GlassyButton(
                            onPressed: () {
                              // Contact support
                              _showContactSupportDialog();
                            },
                            child: const Text(
                              'Contact Support',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassyButton(
                            onPressed: () {
                              // View order details
                              Navigator.pushNamed(context, '/order-details/${widget.orderId}');
                            },
                            child: const Text(
                              'View Details',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
        color = Colors.greenAccent;
        break;
      case 'shipped':
      case 'out for delivery':
        color = Colors.blueAccent;
        break;
      case 'processing':
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrackingStep(Map<String, dynamic> step) {
    final isCompleted = step['completed'] as bool;
    final isLast = _trackingSteps.last == step;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and icon
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.blueAccent : Colors.white24,
              ),
              child: Icon(
                step['icon'] as IconData,
                color: isCompleted ? Colors.white : Colors.white54,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted ? Colors.blueAccent : Colors.white24,
              ),
          ],
        ),

        const SizedBox(width: 16),

        // Step details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step['status'],
                style: TextStyle(
                  color: isCompleted ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step['description'],
                style: TextStyle(
                  color: isCompleted ? Colors.white70 : Colors.white38,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              if (step['timestamp'] != null)
                Text(
                  step['timestamp'],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'Contact Support',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Need help with your order? Our support team is here to assist you.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to support chat or call
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}