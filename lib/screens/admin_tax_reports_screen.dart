import 'package:flutter/material.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../widgets/access_denied_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminTaxReportsScreen extends StatefulWidget {
  const AdminTaxReportsScreen({super.key});

  @override
  State<AdminTaxReportsScreen> createState() => _AdminTaxReportsScreenState();
}

class _AdminTaxReportsScreenState extends State<AdminTaxReportsScreen> {
  List<Map<String, dynamic>> _taxReports = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedPeriod = 'quarterly';

  // Tax summary data
  Map<String, dynamic> _taxSummary = {};

  @override
  void initState() {
    super.initState();
    _loadTaxReports();
  }

  Future<void> _loadTaxReports() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load tax reports (placeholder - would need tax_records table)
      _taxReports = [
        {
          'period': 'Q1 2024',
          'total_tax_collected': 1250.00,
          'sellers_filed': 15,
          'total_sellers': 18,
          'compliance_rate': 83.3,
          'status': 'completed',
        },
        {
          'period': 'Q2 2024',
          'total_tax_collected': 1580.00,
          'sellers_filed': 16,
          'total_sellers': 19,
          'compliance_rate': 84.2,
          'status': 'completed',
        },
        {
          'period': 'Q3 2024',
          'total_tax_collected': 1420.00,
          'sellers_filed': 14,
          'total_sellers': 20,
          'compliance_rate': 70.0,
          'status': 'completed',
        },
        {
          'period': 'Q4 2024',
          'total_tax_collected': 0.00,
          'sellers_filed': 0,
          'total_sellers': 21,
          'compliance_rate': 0.0,
          'status': 'pending',
        },
      ];

      // Calculate tax summary
      final completedReports = _taxReports.where((report) => report['status'] == 'completed');
      final totalTaxCollected = completedReports.fold<double>(0.0, (sum, report) => sum + report['total_tax_collected']);
      final averageCompliance = completedReports.isNotEmpty
          ? completedReports.fold<double>(0.0, (sum, report) => sum + report['compliance_rate']) / completedReports.length
          : 0.0;

      _taxSummary = {
        'total_tax_collected': totalTaxCollected,
        'total_reports': _taxReports.length,
        'completed_reports': completedReports.length,
        'pending_reports': _taxReports.where((report) => report['status'] == 'pending').length,
        'average_compliance': averageCompliance,
        'total_sellers': _taxReports.isNotEmpty ? _taxReports.last['total_sellers'] : 0,
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
      appBar: const GlassyAppBar(title: 'Tax Reports'),
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
          loadingMessage: 'Loading tax reports...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Tax Reports',
                  message: _errorMessage,
                  onRetry: _loadTaxReports,
                  icon: Icons.refresh,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      Row(
                        children: [
                          const Text(
                            'Report Type:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildPeriodButton('Quarterly', 'quarterly'),
                                  const SizedBox(width: 8),
                                  _buildPeriodButton('Annual', 'annual'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Tax Summary
                      const Text(
                        'Tax Summary',
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
                            child: _buildSummaryCard(
                              'Total Collected',
                              '\$${_taxSummary['total_tax_collected']?.toStringAsFixed(2) ?? '0.00'}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Avg Compliance',
                              '${_taxSummary['average_compliance']?.toStringAsFixed(1) ?? '0.0'}%',
                              Icons.check_circle,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Reports Filed',
                              '${_taxSummary['completed_reports'] ?? 0}/${_taxSummary['total_reports'] ?? 0}',
                              Icons.description,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Active Sellers',
                              '${_taxSummary['total_sellers'] ?? 0}',
                              Icons.store,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Tax Reports List
                      const Text(
                        'Tax Reports',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _taxReports.isEmpty
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
                                    'No tax reports available',
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
                              itemCount: _taxReports.length,
                              itemBuilder: (context, index) {
                                final report = _taxReports[index];
                                return _buildTaxReportCard(report);
                              },
                            ),

                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _generateTaxReport,
                              icon: const Icon(Icons.add),
                              label: const Text('Generate Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _exportTaxReports,
                              icon: const Icon(Icons.download),
                              label: const Text('Export'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blueAccent),
                                foregroundColor: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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

  Widget _buildTaxReportCard(Map<String, dynamic> report) {
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
                Text(
                  report['period'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(report['status']),
              ],
            ),

            const SizedBox(height: 12),

            // Report details
            Row(
              children: [
                Expanded(
                  child: _buildReportDetail(
                    'Tax Collected',
                    '\$${report['total_tax_collected'].toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildReportDetail(
                    'Sellers Filed',
                    '${report['sellers_filed']}/${report['total_sellers']}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildReportDetail(
                    'Compliance Rate',
                    '${report['compliance_rate'].toStringAsFixed(1)}%',
                    Icons.check_circle,
                    report['compliance_rate'] >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
                Expanded(
                  child: Container(), // Empty for balance
                ),
              ],
            ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTaxReport(report),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (report['status'] == 'pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _remindSellers(report),
                      icon: const Icon(Icons.notification_important),
                      label: const Text('Remind'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.greenAccent;
        label = 'Completed';
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

  Widget _buildReportDetail(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _generateTaxReport() {
    // Placeholder for report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax report generation functionality - Coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportTaxReports() {
    // Placeholder for export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax reports export functionality - Coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewTaxReport(Map<String, dynamic> report) {
    // Placeholder for detailed view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing tax report for ${report['period']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _remindSellers(Map<String, dynamic> report) {
    // Placeholder for reminder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending reminders for ${report['period']} tax filing'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}