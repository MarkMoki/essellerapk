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

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.getCartItems(_products);
    final total = cartItems.fold(0.0, (sum, item) => sum + (item['product'] as Product).price * (item['quantity'] as int));

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                    child: ListView.builder(
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
                                width: 80,
                                height: 80,
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Quantity: $quantity',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      '\$${product.price * quantity}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                onPressed: () {
                                  cartProvider.removeItem(product.id);
                                },
                              ),
                            ],
                          ),
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
                          'Total: \$${total.toStringAsFixed(2)}',
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