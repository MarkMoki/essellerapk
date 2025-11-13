import 'package:flutter/material.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SellerTaxesScreen extends StatefulWidget {
  const SellerTaxesScreen({super.key});

  @override
  State<SellerTaxesScreen> createState() => _SellerTaxesScreenState();
}

class _SellerTaxesScreenState extends State<SellerTaxesScreen> {
  List<Map<String, dynamic>> _taxRecords = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _totalTaxPaid = 0.0;
  double _pendingTax = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTaxData();
  }

  Future<void> _loadTaxData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // final sellerId = authProvider.user!.id;

      // Load tax records (placeholder - would need tax_records table)
      _taxRecords = [
        {
          'id': '1',
          'period': 'Q1 2024',
          'amount': 45.00,
          'status': 'paid',
          'due_date': DateTime(2024, 3, 31),
          'paid_date': DateTime(2024, 3, 15),
          'reference': 'TAX001',
        },
        {
          'id': '2',
          'period': 'Q2 2024',
          'amount': 67.50,
          'status': 'paid',
          'due_date': DateTime(2024, 6, 30),
          'paid_date': DateTime(2024, 6, 20),
          'reference': 'TAX002',
        },
        {
          'id': '3',
          'period': 'Q3 2024',
          'amount': 52.25,
          'status': 'pending',
          'due_date': DateTime(2024, 9, 30),
          'paid_date': null,
          'reference': 'TAX003',
        },
      ];

      // Calculate totals
      _totalTaxPaid = _taxRecords
          .where((record) => record['status'] == 'paid')
          .fold(0.0, (sum, record) => sum + record['amount']);

      _pendingTax = _taxRecords
          .where((record) => record['status'] == 'pending')
          .fold(0.0, (sum, record) => sum + record['amount']);

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
    if (!authProvider.isSeller) {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Taxes'),
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
          loadingMessage: 'Loading tax information...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Tax Data',
                  message: _errorMessage,
                  onRetry: _loadTaxData,
                  icon: Icons.refresh,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tax overview
                      const Text(
                        'Tax Overview',
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
                            child: _buildTaxCard(
                              'Total Paid',
                              '\$${_totalTaxPaid.toStringAsFixed(2)}',
                              Colors.green,
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTaxCard(
                              'Pending',
                              '\$${_pendingTax.toStringAsFixed(2)}',
                              Colors.orange,
                              Icons.schedule,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Tax information
                      const Text(
                        'Tax Information',
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
                              _buildInfoRow('Tax Rate', '5% of sales revenue'),
                              const SizedBox(height: 12),
                              _buildInfoRow('Filing Frequency', 'Quarterly'),
                              const SizedBox(height: 12),
                              _buildInfoRow('Tax Authority', 'Kenya Revenue Authority'),
                              const SizedBox(height: 12),
                              _buildInfoRow('Tax ID', 'Not registered'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Tax records
                      const Text(
                        'Tax Records',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _taxRecords.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tax records',
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
                              itemCount: _taxRecords.length,
                              itemBuilder: (context, index) {
                                final record = _taxRecords[index];
                                return _buildTaxRecordCard(record);
                              },
                            ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTaxCard(String title, String amount, Color color, IconData icon) {
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
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

  Widget _buildTaxRecordCard(Map<String, dynamic> record) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record['period'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(record['status']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount: \$${record['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Due: ${_formatDate(record['due_date'])}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (record['paid_date'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Paid: ${_formatDate(record['paid_date'])}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Ref: ${record['reference']}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
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
      case 'paid':
        color = Colors.greenAccent;
        label = 'Paid';
        break;
      case 'pending':
        color = Colors.orangeAccent;
        label = 'Pending';
        break;
      case 'overdue':
        color = Colors.redAccent;
        label = 'Overdue';
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}