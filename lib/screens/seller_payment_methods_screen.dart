import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';
import '../constants.dart';

class PaymentMethod {
  final String id;
  final String type; // 'mpesa', 'card', 'bank'
  final String details;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.details,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: json['type'],
      details: json['details'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'details': details,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get maskedDetails {
    switch (type) {
      case 'mpesa':
        // Mask phone number: +254 7XX XXX XXX -> +254 7** *** ***
        return details.replaceAllMapped(
          RegExp(r'(\+254\s7)(\d{2})\s(\d{3})\s(\d{3})'),
          (match) => '${match[1]}** *** ***',
        );
      case 'card':
        // Mask card number: **** **** **** 1234
        final parts = details.split(' ');
        if (parts.length >= 4) {
          return '**** **** **** ${parts.last}';
        }
        return details;
      case 'bank':
        // Show only last 4 digits of account number
        return details.replaceAllMapped(
          RegExp(r'(\d{4})(\d+)$'),
          (match) => '****${match[2]}',
        );
      default:
        return details;
    }
  }

  IconData get icon {
    switch (type) {
      case 'mpesa':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Color get color {
    switch (type) {
      case 'mpesa':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'bank':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class SellerPaymentMethodsScreen extends StatefulWidget {
  const SellerPaymentMethodsScreen({super.key});

  @override
  State<SellerPaymentMethodsScreen> createState() => _SellerPaymentMethodsScreenState();
}

class _SellerPaymentMethodsScreenState extends State<SellerPaymentMethodsScreen> {
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('User not authenticated');
      }

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('payment_methods')
          .select('*')
          .eq('seller_id', authProvider.user!.id)
          .order('created_at', ascending: false);

      _paymentMethods = response.map((json) => PaymentMethod.fromJson(json)).toList();

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

  Future<void> _addPaymentMethod() async {
    // Show dialog to add new payment method
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddPaymentMethodDialog();
      },
    ).then((_) => _loadPaymentMethods());
  }

  Future<void> _deletePaymentMethod(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('payment_methods')
          .delete()
          .eq('id', id);

      setState(() {
        _paymentMethods.removeWhere((method) => method.id == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Payment Methods'),
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
          loadingMessage: 'Loading payment methods...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Payment Methods',
                  message: _errorMessage,
                  onRetry: _loadPaymentMethods,
                  icon: Icons.refresh,
                )
              : Column(
                  children: [
                    // Add Payment Method Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GlassyButton(
                        onPressed: _addPaymentMethod,
                        width: double.infinity,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Add Payment Method'),
                          ],
                        ),
                      ),
                    ),

                    // Payment Methods List
                    Expanded(
                      child: _paymentMethods.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.payment_outlined,
                                    size: 80,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No payment methods added',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add a payment method to receive payments',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadPaymentMethods,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _paymentMethods.length,
                                itemBuilder: (context, index) {
                                  final method = _paymentMethods[index];
                                  return GlassyContainer(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: method.color.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              method.icon,
                                              color: method.color,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      method.type.toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (method.isDefault) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Text(
                                                          'DEFAULT',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  method.maskedDetails,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    backgroundColor: const Color(0xFF16213e),
                                                    title: const Text(
                                                      'Remove Payment Method',
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to remove this payment method?',
                                                      style: TextStyle(color: Colors.white70),
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
                                                          if (mounted) {
                                                            Navigator.of(context).pop();
                                                          }
                                                          _deletePaymentMethod(method.id);
                                                        },
                                                        child: const Text(
                                                          'Remove',
                                                          style: TextStyle(color: Colors.redAccent),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AddPaymentMethodDialog extends StatefulWidget {
  const AddPaymentMethodDialog({super.key});

  @override
  State<AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<AddPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'mpesa';
  final _detailsController = TextEditingController();
  bool _isDefault = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213e),
      title: const Text(
        'Add Payment Method',
        style: TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              dropdownColor: const Color(0xFF16213e),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Payment Type',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                DropdownMenuItem(value: 'card', child: Text('Credit/Debit Card')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _getDetailsLabel(),
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: _getDetailsHint(),
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Required';
                return _validateDetails(value);
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text(
                'Set as default payment method',
                style: TextStyle(color: Colors.white70),
              ),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
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
          onPressed: _addPaymentMethod,
          child: const Text(
            'Add',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  String _getDetailsLabel() {
    switch (_selectedType) {
      case 'mpesa':
        return 'M-Pesa Phone Number';
      case 'card':
        return 'Card Details';
      case 'bank':
        return 'Account Details';
      default:
        return 'Details';
    }
  }

  String _getDetailsHint() {
    switch (_selectedType) {
      case 'mpesa':
        return '+254 7XX XXX XXX';
      case 'card':
        return 'Card number, expiry, CVV';
      case 'bank':
        return 'Bank name, account number';
      default:
        return '';
    }
  }

  String? _validateDetails(String value) {
    switch (_selectedType) {
      case 'mpesa':
        final phoneRegex = RegExp(r'^\+254\s7\d{2}\s\d{3}\s\d{3}$');
        if (!phoneRegex.hasMatch(value)) {
          return 'Please enter a valid M-Pesa number (+254 7XX XXX XXX)';
        }
        break;
      case 'card':
        // Basic validation - in real app, use proper card validation
        if (value.length < 10) {
          return 'Please enter complete card details';
        }
        break;
      case 'bank':
        if (value.length < 5) {
          return 'Please enter complete account details';
        }
        break;
    }
    return null;
  }

  void _addPaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('User not authenticated');
      }

      final supabase = Supabase.instance.client;
      final paymentMethodId = DateTime.now().millisecondsSinceEpoch.toString();

      await supabase.from('payment_methods').insert({
        'id': paymentMethodId,
        'seller_id': authProvider.user!.id,
        'type': _selectedType,
        'details': _detailsController.text,
        'is_default': _isDefault,
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}