import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/product_service.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';

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
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productService.fetchProducts();
    if (mounted) {
      setState(() {
        _products = products.map((product) => Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : 'https://via.placeholder.com/300x300?text=No+Image',
          stock: product.stock,
        )).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartItems = cartProvider.getCartItems(_products);
    final total = cartItems.fold(0.0, (sum, item) => sum + (item['product'] as Product).price * (item['quantity'] as int));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassyAppBar(title: 'Checkout'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                              child: Text(
                                product.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Text(
                              'Qty: $quantity - \$${product.price * quantity}',
                              style: const TextStyle(color: Colors.white70),
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
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'M-Pesa Phone Number (254...)',
                        prefixIcon: Icon(Icons.phone, color: Colors.white70),
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : GlassyButton(
                            onPressed: () => _placeOrder(authProvider.user!.id, cartItems, total),
                            width: double.infinity,
                            child: const Text(
                              'Pay with M-Pesa',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(String userId, List<Map<String, dynamic>> cartItems, double total) async {
    setState(() {
      _isLoading = true;
    });
    try {
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
        status: 'pending_payment',
        createdAt: DateTime.now(),
      );

      await _orderService.createOrder(order);

      // Initiate payment
      await _paymentService.initiateSTKPush(_phoneController.text, total, orderId);

      // Clear cart
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed. Check your phone for M-Pesa prompt.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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