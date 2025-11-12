import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../models/wishlist.dart';
import '../services/wishlist_service.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../widgets/glassy_button.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Wishlist? _wishlist;
  List<Map<String, dynamic>>? _wishlistWithProducts;
  bool _isLoading = false;
  final Set<String> _selectedItems = {};
  final WishlistService _wishlistService = WishlistService();

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final wishlist = await _wishlistService.getWishlist(authProvider.user!.id);
      final wishlistWithProducts = await _wishlistService.getWishlistWithProducts(authProvider.user!.id);

      if (mounted) {
        setState(() {
          _wishlist = wishlist;
          _wishlistWithProducts = wishlistWithProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wishlist: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedItems.contains(productId)) {
        _selectedItems.remove(productId);
      } else {
        _selectedItems.add(productId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_wishlistWithProducts != null && _selectedItems.length == _wishlistWithProducts!.length) {
        _selectedItems.clear();
      } else if (_wishlistWithProducts != null) {
        _selectedItems.addAll(_wishlistWithProducts!.map((item) => item['wishlist_items']['product_id'] as String));
      }
    });
  }

  Future<void> _removeSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Remove Items', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${_selectedItems.length} item(s) from wishlist?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final productId in _selectedItems) {
          await _wishlistService.removeFromWishlist(
            userId: authProvider.user!.id,
            productId: productId,
          );
        }

        // Reload wishlist
        await _loadWishlist();
        _selectedItems.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Items removed from wishlist')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove items: ${e.toString().replaceFirst('Exception: ', '')}')),
          );
        }
      }
    }
  }

  void _addToCart(String productId) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(productId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart')),
    );
  }

  void _shareWishlist() {
    // Would implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlassyAppBar(
        title: 'My Wishlist',
        actions: [
          if (_wishlistWithProducts != null && _wishlistWithProducts!.isNotEmpty) ...[
            IconButton(
              onPressed: _selectAll,
              icon: Icon(
                _selectedItems.length == _wishlistWithProducts!.length
                    ? Icons.check_box
                    : _selectedItems.isNotEmpty
                        ? Icons.indeterminate_check_box
                        : Icons.check_box_outline_blank,
                color: Colors.white,
              ),
              tooltip: 'Select All',
            ),
            if (_selectedItems.isNotEmpty)
              IconButton(
                onPressed: _removeSelectedItems,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: 'Remove Selected',
              ),
            IconButton(
              onPressed: _shareWishlist,
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Share Wishlist',
            ),
          ],
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wishlist == null
                ? const Center(
                    child: Text(
                      'Please log in to view your wishlist',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Wishlist Stats
                        if (_wishlistWithProducts != null && _wishlistWithProducts!.isNotEmpty)
                          GlassyContainer(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  '${_wishlistWithProducts!.length}',
                                  'Items',
                                  Icons.favorite,
                                ),
                                _buildStatItem(
                                  '${_selectedItems.length}',
                                  'Selected',
                                  Icons.check_circle,
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Wishlist Items
                        Expanded(
                          child: (_wishlistWithProducts == null || _wishlistWithProducts!.isEmpty)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.favorite_border,
                                        size: 64,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Your wishlist is empty',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start adding items you love!',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      GlassyButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/shop');
                                        },
                                        child: const Text(
                                          'Browse Products',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _wishlistWithProducts?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final item = _wishlistWithProducts![index];
                                    return _buildWishlistItem(item);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> item) {
    final wishlistItem = item['wishlist_items'] as Map<String, dynamic>;
    final product = item['products'] as Map<String, dynamic>?;
    final productId = wishlistItem['product_id'] as String;
    final isSelected = _selectedItems.contains(productId);

    return GlassyContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleSelection(productId),
        child: Row(
          children: [
            // Selection Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleSelection(productId),
              fillColor: WidgetStateProperty.resolveWith(
                (states) => isSelected ? Colors.blueAccent : Colors.transparent,
              ),
              checkColor: Colors.white,
            ),

            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white24,
              ),
              child: product?['image_url'] != null
                  ? Image.network(
                      product!['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image,
                        color: Colors.white54,
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      color: Colors.white54,
                    ),
            ),

            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?['name'] ?? 'Product $productId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added ${DateTime.parse(wishlistItem['added_at']).toString().split(' ')[0]}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        ' ${product?['rating']?.toString() ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                Text(
                  '\$${(product?['price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GlassyButton(
                  onPressed: () => _addToCart(productId),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}