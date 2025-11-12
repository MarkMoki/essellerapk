import 'package:flutter/material.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';
import '../services/search_service.dart';
import '../models/product.dart';
import '../constants.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final SearchService _searchService = SearchService();
  List<String> _categories = [];
  bool _isLoading = true;

  // Static category metadata for UI
  final Map<String, Map<String, dynamic>> _categoryMetadata = {
    'Electronics': {
      'icon': Icons.devices,
      'color': Colors.blueAccent,
      'subcategories': ['Phones', 'Laptops', 'Tablets', 'Accessories'],
    },
    'Clothing': {
      'icon': Icons.checkroom,
      'color': Colors.pinkAccent,
      'subcategories': ['Men', 'Women', 'Kids', 'Shoes'],
    },
    'Home & Garden': {
      'icon': Icons.home,
      'color': Colors.greenAccent,
      'subcategories': ['Furniture', 'Decor', 'Kitchen', 'Garden'],
    },
    'Sports': {
      'icon': Icons.sports_soccer,
      'color': Colors.orangeAccent,
      'subcategories': ['Fitness', 'Outdoor', 'Team Sports', 'Water Sports'],
    },
    'Books': {
      'icon': Icons.book,
      'color': Colors.purpleAccent,
      'subcategories': ['Fiction', 'Non-Fiction', 'Textbooks', 'Comics'],
    },
    'Beauty': {
      'icon': Icons.face,
      'color': Colors.redAccent,
      'subcategories': ['Skincare', 'Makeup', 'Hair Care', 'Fragrance'],
    },
    'Toys': {
      'icon': Icons.toys,
      'color': Colors.yellowAccent,
      'subcategories': ['Action Figures', 'Dolls', 'Educational', 'Outdoor'],
    },
    'Automotive': {
      'icon': Icons.directions_car,
      'color': Colors.grey,
      'subcategories': ['Parts', 'Accessories', 'Tools', 'Electronics'],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _searchService.getCategories();
      setState(() {
        _categories = categories.isNotEmpty ? categories : _categoryMetadata.keys.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _categories = _categoryMetadata.keys.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Categories'),
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
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop by Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find what you\'re looking for',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final categoryName = _categories[index];
                          final categoryData = {
                            'name': categoryName,
                            ...(_categoryMetadata[categoryName] ?? {
                              'icon': Icons.category,
                              'color': Colors.grey,
                              'subcategories': [],
                            }),
                          };
                          return _buildCategoryCard(context, categoryData);
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(context, category),
      child: GlassyContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Category Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: category['color'].withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              category['icon'],
              color: category['color'],
              size: 30,
            ),
          ),

          const SizedBox(height: 12),

          // Category Name
          Text(
            category['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Subcategories Preview
          Text(
            '${category['subcategories'].length} subcategories',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(category: category),
      ),
    );
  }
}

class CategoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final SearchService _searchService = SearchService();
  late List<Product> _products;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
  }

  Future<void> _loadCategoryProducts() async {
    try {
      final products = await _searchService.getProductsByCategory(widget.category['name']);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _products = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getUserFriendlyErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlassyAppBar(
        title: widget.category['name'],
        actions: [
          IconButton(
            onPressed: () {
              // Show sort/filter options
              _showSortOptions(context);
            },
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort & Filter',
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
        child: Column(
          children: [
            // Subcategories
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.category['subcategories'].length,
                itemBuilder: (context, index) {
                  final subcategory = widget.category['subcategories'][index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(subcategory),
                      selected: false, // Would be managed by state
                      onSelected: (selected) {
                        // Handle subcategory selection
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      selectedColor: widget.category['color'],
                      checkmarkColor: Colors.white,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),

            // Products Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(_products[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details
        Navigator.pushNamed(context, '/product-details', arguments: product);
      },
      child: GlassyContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white24,
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white54,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Product Name
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Category
            if (product.category != null)
              Text(
                product.category!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 4),

            // Price
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Newest', 'Price: Low to High', 'Price: High to Low', 'Rating', 'Popularity']
                .map((option) => ListTile(
                      title: Text(
                        option,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Apply sorting
                      },
                    )),
          ],
        ),
      ),
    );
  }
}