import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';
import '../widgets/bottom_navigation.dart';
import 'admin_dashboard.dart';
import 'shop_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAdmin) {
      return const AdminDashboard();
    }

    Widget getCurrentScreen() {
      switch (_currentIndex) {
        case 0:
          return _buildDashboard();
        case 1:
          return const ShopScreen();
        case 2:
          return const CartScreen();
        case 3:
          return const ProfileScreen();
        default:
          return _buildDashboard();
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlassyAppBar(
        title: 'Esaller',
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final itemCount = cartProvider.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              authProvider.signOut();
            },
          ),
        ],
      ),
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
        child: getCurrentScreen(),
      ),
      bottomNavigationBar: GlassyBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60), // Account for app bar
          Text(
            'Welcome to Esaller',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 600 ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover amazing products at great prices',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassyContainer(
                          height: isWide ? 140 : 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                color: Colors.white,
                                size: isWide ? 50 : 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Shop Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWide ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: isWide ? 24 : 16),
                      Expanded(
                        child: GlassyContainer(
                          height: isWide ? 140 : 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category,
                                color: Colors.white,
                                size: isWide ? 50 : 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Categories',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWide ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isWide ? 24 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: GlassyContainer(
                          height: isWide ? 140 : 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_offer,
                                color: Colors.white,
                                size: isWide ? 50 : 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Deals',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWide ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: isWide ? 24 : 16),
                      Expanded(
                        child: GlassyContainer(
                          height: isWide ? 140 : 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: isWide ? 50 : 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Favorites',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWide ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            'Featured Products',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GlassyButton(
            onPressed: () {
              setState(() {
                _currentIndex = 1; // Switch to shop tab
              });
            },
            width: double.infinity,
            child: Text(
              'Browse All Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}