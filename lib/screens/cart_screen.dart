import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../widgets/professional_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];

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

  void _showEditQuantityDialog(BuildContext context, String productId, int currentQuantity) {
    final TextEditingController quantityController = TextEditingController(text: currentQuantity.toString());
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: const Text(
            'Edit Quantity',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Quantity',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
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
                final newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null && newQuantity > 0) {
                  final product = _products.firstWhere((p) => p.id == productId);
                  if (newQuantity > product.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cannot set quantity above available stock (${product.stock})'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  } else {
                    cartProvider.updateQuantity(productId, newQuantity);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quantity updated'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.getCartItems(_products);
    final total = cartProvider.getTotalAmount(_products);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Cart'),
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
        child: cartItems.isEmpty
            ? const Center(
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final imageSize = screenWidth > 600 ? 100.0 : 80.0;
                        final fontSize = screenWidth > 600 ? 18.0 : 16.0;
                        final priceFontSize = screenWidth > 600 ? 18.0 : 16.0;

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final product = item['product'] as Product;
                            final quantity = item['quantity'] as int;
                            return GlassyContainer(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  ProfessionalImage(
                                    imageUrl: product.imageUrl,
                                    width: imageSize,
                                    height: imageSize,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: fontSize,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ksh${product.price.toStringAsFixed(2)} each',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: priceFontSize - 2,
                                          ),
                                        ),
                                        Text(
                                          'Subtotal: Ksh${(product.price * quantity).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: priceFontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: Colors.redAccent,
                                          size: screenWidth > 600 ? 24 : 20,
                                        ),
                                        onPressed: () {
                                          cartProvider.removeItem(product.id);
                                        },
                                      ),
                                      Text(
                                        '$quantity',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth > 600 ? 16 : 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add_circle,
                                          color: Colors.greenAccent,
                                          size: screenWidth > 600 ? 24 : 20,
                                        ),
                                        onPressed: () {
                                          if (cartProvider.getQuantity(product.id) < product.stock) {
                                            cartProvider.addItem(product.id);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Cannot add more ${product.name} - stock limit reached'),
                                                backgroundColor: Colors.orangeAccent,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                          size: screenWidth > 600 ? 24 : 20,
                                        ),
                                        onPressed: () {
                                          _showEditQuantityDialog(context, product.id, quantity);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  GlassyContainer(
                    margin: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: Ksh${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GlassyButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/checkout');
                          },
                          child: const Text(
                            'Checkout',
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
    );
  }
}