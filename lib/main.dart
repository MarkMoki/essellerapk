import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'models/user.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/seller_products_screen.dart';
import 'screens/seller_payment_methods_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/new_return_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/user_addresses_screen.dart';
import 'screens/add_address_screen.dart';
import 'screens/edit_address_screen.dart';
import 'widgets/error_boundary.dart';

class RouteGuard {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // This will be called from the MaterialApp, so we need to get context differently
    // For now, let's use a simpler approach - check auth in each screen
    // TODO: Implement proper route guards with context access

    Widget screen;
    switch (settings.name) {
      case '/auth':
        screen = const AuthScreen();
        break;
      case '/home':
        screen = const HomeScreen();
        break;
      case '/cart':
        screen = const CartScreen();
        break;
      case '/checkout':
        screen = const CheckoutScreen();
        break;
      case '/orders':
        screen = const OrdersScreen();
        break;
      case '/settings':
        screen = const SettingsScreen();
        break;
      case '/help':
        screen = const HelpScreen();
        break;
      case '/admin':
        screen = const AdminDashboard();
        break;
      case '/seller/dashboard':
        screen = const SellerDashboardScreen();
        break;
      case '/seller/products':
        screen = const SellerProductsScreen();
        break;
      case '/seller/payment-methods':
        screen = const SellerPaymentMethodsScreen();
        break;
      case '/forgot-password':
        screen = const ForgotPasswordScreen();
        break;
      case '/new-return':
        screen = const NewReturnScreen();
        break;
      case '/user-profile':
        screen = const UserProfileScreen();
        break;
      case '/user-addresses':
        screen = const UserAddressesScreen();
        break;
      case '/add-address':
        screen = const AddAddressScreen();
        break;
      case '/edit-address':
        final address = settings.arguments as Address?;
        screen = address != null ? EditAddressScreen(address: address) : const Scaffold(body: Center(child: Text('Address not found')));
        break;
      default:
        screen = Scaffold(
          body: Center(
            child: Text('Route ${settings.name} not found'),
          ),
        );
    }

    return MaterialPageRoute(builder: (_) => RouteGuardWidget(child: screen));
  }
}

class RouteGuardWidget extends StatelessWidget {
  final Widget child;

  const RouteGuardWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Define route permissions
    final routePermissions = {
      '/auth': {'requiresAuth': false, 'roles': <String>[]},
      '/home': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/cart': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/checkout': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/orders': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/settings': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/help': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/admin': {'requiresAuth': true, 'roles': ['admin']},
      '/seller/dashboard': {'requiresAuth': true, 'roles': ['seller']},
      '/seller/products': {'requiresAuth': true, 'roles': ['seller']},
      '/seller/payment-methods': {'requiresAuth': true, 'roles': ['seller']},
      '/forgot-password': {'requiresAuth': false, 'roles': <String>[]},
      '/new-return': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/user-profile': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/user-addresses': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/add-address': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
      '/edit-address': {'requiresAuth': true, 'roles': ['user', 'seller', 'admin']},
    };

    final currentRoute = ModalRoute.of(context)?.settings.name;
    final routeConfig = routePermissions[currentRoute];

    if (routeConfig != null) {
      // Check authentication
      if (routeConfig['requiresAuth'] == true && !authProvider.isAuthenticated) {
        return const AuthScreen();
      }

      // Check role permissions
      final allowedRoles = routeConfig['roles'] as List<String>;
      if (allowedRoles.isNotEmpty && !allowedRoles.contains(authProvider.role)) {
        return Scaffold(
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You don\'t have permission to access this page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: ErrorBoundary(
        child: MaterialApp(
          title: 'Esaller',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: Colors.transparent,
            scaffoldBackgroundColor: const Color(0xFF0F0F23),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                shadowColor: Colors.white30,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white54),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
            ),
          ),
          home: const AuthWrapper(),
          onGenerateRoute: (settings) => RouteGuard.generateRoute(settings),
        ),
      ),
    );
  }

}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 🔒 Not logged in → go to AuthScreen
    if (!authProvider.isAuthenticated) {
      return const AuthScreen();
    }

    // 👑 Admin → Admin Dashboard
    if (authProvider.isAdmin) {
      return const AdminDashboard();
    }

    // 🛒 Seller → Seller Dashboard
    if (authProvider.isSeller) {
      return const SellerDashboardScreen();
    }

    // 🏠 Regular user → Home
    return const HomeScreen();
  }
}
  