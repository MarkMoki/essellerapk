import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../services/payout_service.dart';
import '../services/email_service.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../constants.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SellerPayoutsScreen extends StatefulWidget {
  const SellerPayoutsScreen({super.key});

  @override
  State<SellerPayoutsScreen> createState() => _SellerPayoutsScreenState();
}

class _SellerPayoutsScreenState extends State<SellerPayoutsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PayoutService _payoutService = PayoutService();
  final EmailService _emailService = EmailService();
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> _payouts = [];
  List<Map<String, dynamic>> _payoutMethods = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _availableBalance = 0.0;
  double _pendingPayouts = 0.0;

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sellerId = authProvider.user!.id;

      // Load real payout history
      _payouts = await _payoutService.getSellerPayoutHistory(sellerId);

      // Calculate real balances
      _availableBalance = await _payoutService.getSellerBalance(sellerId);

      // Calculate pending payouts
      _pendingPayouts = _payouts
          .where((payout) => payout['status'] == 'pending')
          .fold(0.0, (sum, payout) => sum + (payout['amount'] as num).toDouble());

      // Load payout methods
      _payoutMethods = await _payoutService.getSellerPayoutMethods(sellerId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isSeller) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Payouts'),
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
          loadingMessage: 'Loading payouts...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Payouts',
                  message: _errorMessage,
                  onRetry: _loadPayoutData,
                  icon: Icons.refresh,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance overview
                      const Text(
                        'Balance Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBalanceCard(
                              'Available Balance',
                              '\$${_availableBalance.toStringAsFixed(2)}',
                              Colors.green,
                              Icons.account_balance_wallet,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBalanceCard(
                              'Pending Payouts',
                              '\$${_pendingPayouts.toStringAsFixed(2)}',
                              Colors.orange,
                              Icons.schedule,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Request payout button
                      ElevatedButton.icon(
                        onPressed: _availableBalance > 0 ? _requestPayout : null,
                        icon: const Icon(Icons.payment),
                        label: const Text('Request Payout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Payout history
                      const Text(
                        'Payout History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _payouts.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.payment_outlined,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No payouts yet',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _payouts.length,
                              itemBuilder: (context, index) {
                                final payout = _payouts[index];
                                return _buildPayoutCard(payout);
                              },
                            ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount, Color color, IconData icon) {
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
              amount,
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

  Widget _buildPayoutCard(Map<String, dynamic> payout) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (payout['status']) {
      case 'completed':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'pending':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
      case 'processing':
        statusColor = Colors.blueAccent;
        statusIcon = Icons.hourglass_top;
        statusText = 'Processing';
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),

                // Payout details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${payout['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payout['payment_method'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (payout['reference'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Ref: ${payout['reference']}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Date and status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(DateTime.parse(payout['requested_at'])),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Additional details for rejected payouts
            if (payout['status'] == 'rejected' && payout['rejection_reason'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${payout['rejection_reason']}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Processing/Completed timestamps
            if (payout['processed_at'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Processed: ${_formatDate(DateTime.parse(payout['processed_at']))}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                ),
              ),
            ],

            if (payout['completed_at'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Completed: ${_formatDate(DateTime.parse(payout['completed_at']))}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestPayout() async {
    if (_payoutMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a payout method first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    Map<String, dynamic>? selectedMethod;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Request Payout',
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available balance: \$${_availableBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: selectedMethod,
                dropdownColor: const Color(0xFF1a1a2e),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Payout Method',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                ),
                items: _payoutMethods.map((method) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: method,
                    child: Text(
                      '${method['method']} - ${method['details']['account_number'] ?? method['details']['phone'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMethod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount to withdraw',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                ),
              ),
            ],
          ),
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
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0 && amount <= _availableBalance && selectedMethod != null) {
                Navigator.of(context).pop({
                  'amount': amount,
                  'method': selectedMethod,
                });
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
            ),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        // Capture auth provider before async operations
        final authProvider = Provider.of<AuthProvider>(context, listen: false); // ignore: use_build_context_synchronously
        final sellerId = authProvider.user!.id;

        await _payoutService.createPayoutRequest(
          sellerId: sellerId,
          amount: result['amount'],
          paymentMethod: result['method']['method'],
          paymentDetails: result['method']['details'],
        );

        // Send notification
        await _notificationService.createNotification(
          userId: sellerId,
          type: NotificationType.payoutReady,
          title: 'Payout Request Submitted',
          message: 'Your payout request of \$${result['amount'].toStringAsFixed(2)} has been submitted and is pending approval.',
          data: {
            'amount': result['amount'],
            'method': result['method']['method'],
          },
        );

        // Send email notification
        final seller = await _supabase.from('sellers').select('name, email').eq('id', sellerId).single();
        await _emailService.sendPayoutNotificationEmail(
          toEmail: seller['email'],
          sellerName: seller['name'],
          payoutAmount: result['amount'],
          payoutMethod: result['method']['method'],
        );

        // Refresh data
        // Refresh data
        await _loadPayoutData();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
              SnackBar(
                content: Text("Payout request of \${result['amount'].toStringAsFixed(2)} submitted"),
                backgroundColor: Colors.green,
              ),
            );
          });
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
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}