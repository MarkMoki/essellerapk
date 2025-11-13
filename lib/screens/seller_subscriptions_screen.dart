import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../widgets/access_denied_screen.dart';
import '../models/seller.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class SellerSubscriptionsScreen extends StatefulWidget {
  const SellerSubscriptionsScreen({super.key});

  @override
  State<SellerSubscriptionsScreen> createState() => _SellerSubscriptionsScreenState();
}

class _SellerSubscriptionsScreenState extends State<SellerSubscriptionsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Seller? _seller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sellerId = authProvider.user!.id;

      final sellerData = await _supabase.from('sellers').select().eq('id', sellerId).single();
      _seller = Seller.fromJson(sellerData);

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
      appBar: const GlassyAppBar(title: 'Subscription'),
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
          loadingMessage: 'Loading subscription...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Subscription',
                  message: _errorMessage,
                  onRetry: _loadSubscriptionData,
                  icon: Icons.refresh,
                )
              : _seller == null
                  ? const Center(
                      child: Text(
                        'Seller information not available',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentPlanSection(),
                          const SizedBox(height: 32),
                          _buildPlanFeaturesSection(),
                          const SizedBox(height: 32),
                          _buildSubscriptionActionsSection(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GlassyContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _seller!.isExpired ? Icons.warning : Icons.star,
                      color: _seller!.isExpired ? Colors.redAccent : Colors.orangeAccent,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _seller!.isExpired ? 'Expired Plan' : 'Active Seller Plan',
                            style: TextStyle(
                              color: _seller!.isExpired ? Colors.redAccent : Colors.orangeAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _seller!.isExpired
                                ? 'Your subscription has expired'
                                : 'Monthly seller subscription',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPlanDetail('Status', _seller!.isExpired ? 'Expired' : 'Active'),
                const SizedBox(height: 8),
                _buildPlanDetail('Expires', _formatDate(_seller!.expiresAt)),
                const SizedBox(height: 8),
                _buildPlanDetail('Days Remaining', _seller!.timeUntilExpiration.inDays.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plan Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GlassyContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFeature('Unlimited products', true),
                _buildFeature('Order management', true),
                _buildFeature('Analytics dashboard', true),
                _buildFeature('Customer support', true),
                _buildFeature('Payment processing', true),
                _buildFeature('Tax reporting', !_seller!.isExpired),
                _buildFeature('Priority support', !_seller!.isExpired),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _seller!.isExpired ? _buildRenewalActions() : _buildManagementActions(),
    );
  }

  List<Widget> _buildRenewalActions() {
    return [
      const Text(
        'Renew Your Subscription',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      GlassyContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Your seller account has expired. Renew your subscription to regain access to all seller features.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _renewSubscription,
                icon: const Icon(Icons.refresh),
                label: const Text('Renew Subscription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildManagementActions() {
    return [
      const Text(
        'Subscription Management',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      GlassyContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _upgradePlan,
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _cancelSubscription,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Subscription'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildPlanDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(String feature, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            feature,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white60,
              fontSize: 14,
              decoration: enabled ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renewSubscription() async {
    // Placeholder for renewal logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription renewal initiated. Contact admin for payment.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _upgradePlan() async {
    // Placeholder for upgrade logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan upgrade options will be available soon.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Cancel Subscription',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to seller features at the end of your current billing period.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Keep Subscription',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Placeholder for cancellation logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription will be cancelled at the end of the billing period.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}