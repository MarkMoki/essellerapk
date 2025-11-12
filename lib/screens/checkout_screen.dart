import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/product_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _phoneController = TextEditingController();
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  final ProductService _productService = ProductService();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.fetchProducts();
      if (mounted) {
        setState(() {
          _products = products;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load product information. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartItems = cartProvider.getCartItems(_products);
    final total = cartProvider.getTotalAmount(_products);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Checkout'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingMessage: 'Processing your order...',
        child: Container(
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
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Checkout',
                  message: _errorMessage,
                  onRetry: _loadProducts,
                  icon: Icons.refresh,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isWide = screenWidth > 600;
                    final padding = isWide ? 32.0 : 16.0;
                    final totalFontSize = isWide ? 24.0 : 20.0;
                    final buttonFontSize = isWide ? 18.0 : 16.0;

                    return Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        children: [
                          Expanded(
                            child: GlassyContainer(
                              child: ListView.builder(
                                itemCount: cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = cartItems[index];
                                  final product = item['product'] as Product;
                                  final quantity = item['quantity'] as int;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isWide ? 16 : 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Qty: $quantity × Ksh${product.price.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: isWide ? 14 : 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Ksh${(product.price * quantity).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isWide ? 16 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GlassyContainer(
                            child: Column(
                              children: [
                                Text(
                                  'Total: Ksh${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: totalFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'M-Pesa Phone Number (254...)',
                                    hintText: 'e.g., 254712345678',
                                    prefixIcon: Icon(Icons.phone, color: Colors.white70),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.white),
                                  maxLength: 12,
                                ),
                                const SizedBox(height: 20),
                                GlassyButton(
                                  onPressed: () => _placeOrder(authProvider.user!.id, cartItems, total),
                                  width: double.infinity,
                                  child: Text(
                                    'Pay with M-Pesa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: buttonFontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(String userId, List<Map<String, dynamic>> cartItems, double total) async {
    // Validate phone number
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your M-Pesa phone number'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!RegExp(r'^254\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number in format: 254XXXXXXXXX'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check connectivity first
      final connectivity = await _connectivityService.checkConnectivity();
      if (!connectivity['internet']!) {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      if (!connectivity['database']!) {
        throw Exception('Unable to connect to the server. Please try again later.');
      }

      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final items = cartItems.map((item) {
        final product = item['product'] as Product;
        final quantity = item['quantity'] as int;
        return OrderItem(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          price: product.price,
        );
      }).toList();

      final order = Order(
        id: orderId,
        userId: userId,
        items: items,
        totalAmount: total,
        status: OrderStatus.pendingPayment,
        createdAt: DateTime.now(),
      );

      await _orderService.createOrder(order);

      // Initiate payment
      await _paymentService.initiateSTKPush(
        phoneNumber: phone,
        amount: total,
        orderId: orderId,
      );

      // Clear cart
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully! Check your phone for M-Pesa prompt.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $errorMessage'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _placeOrder(userId, cartItems, total),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}