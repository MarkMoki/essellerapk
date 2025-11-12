import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../providers/auth_provider.dart';
import '../services/returns_service.dart';

class NewReturnScreen extends StatefulWidget {
  const NewReturnScreen({super.key});

  @override
  State<NewReturnScreen> createState() => _NewReturnScreenState();
}

class _NewReturnScreenState extends State<NewReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedOrderId;
  List<Map<String, dynamic>> _eligibleOrders = [];
  bool _isLoading = false;
  final ReturnsService _returnsService = ReturnsService();

  final List<String> _returnReasons = [
    'Defective product',
    'Wrong item received',
    'Changed mind',
    'Damaged in shipping',
    'Poor quality',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadEligibleOrders();
  }

  Future<void> _loadEligibleOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      // Get user's delivered orders from the last 30 days
      // Note: This would need to be implemented in a real service
      // For now, we'll show a placeholder
      setState(() {
        _eligibleOrders = [
          {'id': 'ORD001', 'date': DateTime.now().subtract(const Duration(days: 5))},
          {'id': 'ORD002', 'date': DateTime.now().subtract(const Duration(days: 10))},
        ];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReturnRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an order')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isLoading = true);
    try {
      // Create return request
      await _returnsService.createReturnRequest(
        userId: authProvider.user!.id,
        orderId: _selectedOrderId!,
        items: [], // Would need to get order items
        reason: _reasonController.text,
        description: _descriptionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return request submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit return request: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'New Return Request'),
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
                child: GlassyContainer(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedOrderId,
                          decoration: const InputDecoration(
                            labelText: 'Order ID',
                            prefixIcon: Icon(Icons.shopping_cart, color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF16213e),
                          items: _eligibleOrders.map((order) {
                            return DropdownMenuItem<String>(
                              value: order['id'],
                              child: Text('Order ${order['id']} - ${order['date'].toString().split(' ')[0]}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedOrderId = value);
                          },
                          validator: (value) {
                            if (value == null) return 'Please select an order';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Return Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Reason for Return',
                            prefixIcon: Icon(Icons.flag, color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF16213e),
                          items: _returnReasons.map((reason) {
                            return DropdownMenuItem<String>(
                              value: reason,
                              child: Text(reason),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _reasonController.text = value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please select a reason';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            prefixIcon: Icon(Icons.description, color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value != null && value.length > 500) {
                              return 'Description must be less than 500 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Important Notes:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Returns must be requested within 30 days of delivery\n'
                          '• Items must be in original condition\n'
                          '• Refund will be processed to original payment method\n'
                          '• Processing may take 5-7 business days',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        GlassyButton(
                          onPressed: _submitReturnRequest,
                          width: double.infinity,
                          child: const Text(
                            'Submit Return Request',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}