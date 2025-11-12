import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/retry_widget.dart';

class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() => _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState extends State<AdminContentManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedTab = 'products';

  // Content data
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load products
      final productsResponse = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      _products = List<Map<String, dynamic>>.from(productsResponse);

      // Load categories (placeholder)
      _categories = [
        {'id': '1', 'name': 'Electronics', 'product_count': 25},
        {'id': '2', 'name': 'Clothing', 'product_count': 18},
        {'id': '3', 'name': 'Home & Garden', 'product_count': 12},
      ];

      // Load users
      final usersResponse = await _supabase
          .from('profiles')
          .select()
          .limit(50);

      _users = List<Map<String, dynamic>>.from(usersResponse);

      // Load reviews
      final reviewsResponse = await _supabase
          .from('reviews')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      _reviews = List<Map<String, dynamic>>.from(reviewsResponse);

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
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Content Management'),
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
          loadingMessage: 'Loading content...',
          child: _hasError
              ? RetryWidget(
                  title: 'Failed to Load Content',
                  message: _errorMessage,
                  onRetry: _loadContent,
                  icon: Icons.refresh,
                )
              : Column(
                  children: [
                    // Tab selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTabButton('Products', 'products'),
                            const SizedBox(width: 8),
                            _buildTabButton('Categories', 'categories'),
                            const SizedBox(width: 8),
                            _buildTabButton('Users', 'users'),
                            const SizedBox(width: 8),
                            _buildTabButton('Reviews', 'reviews'),
                          ],
                        ),
                      ),
                    ),

                    // Content area
                    Expanded(
                      child: _buildContentArea(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    final isSelected = _selectedTab == tab;
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
          _selectedTab = tab;
        });
      },
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      selectedColor: Colors.orangeAccent.withValues(alpha: 0.3),
      checkmarkColor: Colors.orangeAccent,
    );
  }

  Widget _buildContentArea() {
    switch (_selectedTab) {
      case 'products':
        return _buildProductsTab();
      case 'categories':
        return _buildCategoriesTab();
      case 'users':
        return _buildUsersTab();
      case 'reviews':
        return _buildReviewsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Header with stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_products.length} Products',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addNewProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Products list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_categories.length} Categories',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addNewCategory,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_users.length} Users',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return _buildUserCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_reviews.length} Reviews',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _buildReviewCard(review);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(product['image_url'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product['price']?.toString() ?? '0.00'}',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product['stock'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => _editProduct(product),
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  tooltip: 'Edit Product',
                ),
                IconButton(
                  onPressed: () => _deleteProduct(product),
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Delete Product',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.category,
              color: Colors.orangeAccent,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category['product_count']} products',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _editCategory(category),
                  icon: const Icon(Icons.edit, color: Colors.white70),
                ),
                IconButton(
                  onPressed: () => _deleteCategory(category),
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.orangeAccent,
              child: Text(
                (user['email'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['email'] ?? 'Unknown User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${user['role'] ?? 'user'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _viewUserDetails(user),
              icon: const Icon(Icons.visibility, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return GlassyContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Product: ${review['product_id']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.orangeAccent,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['comment'] ?? 'No comment',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By: ${review['user_id']}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  onPressed: () => _moderateReview(review),
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  tooltip: 'Moderate Review',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewProduct() {
    // Navigate to add product screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add product functionality - Coming soon')),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    // Navigate to edit product screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit product functionality - Coming soon')),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Delete Product', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${product['name']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('products').delete().eq('id', product['id']);
        await _loadContent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete product: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _addNewCategory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add category functionality - Coming soon')),
    );
  }

  void _editCategory(Map<String, dynamic> category) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit category functionality - Coming soon')),
    );
  }

  void _deleteCategory(Map<String, dynamic> category) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete category functionality - Coming soon')),
    );
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View user details - Coming soon')),
    );
  }

  void _moderateReview(Map<String, dynamic> review) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review moderation - Coming soon')),
    );
  }
}