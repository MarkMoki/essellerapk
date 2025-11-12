import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/review.dart';
import '../widgets/glassy_app_bar.dart';
import '../widgets/glassy_container.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Review> _myReviews = [];
  List<Review> _productReviews = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        // Would integrate with review service
        // For now, create sample data
        _myReviews = List.generate(
          5,
          (index) => Review(
            id: 'review_$index',
            userId: authProvider.user!.id,
            productId: 'product_$index',
            rating: 4 + (index % 2),
            title: 'Great product!',
            comment: 'This product exceeded my expectations. Highly recommend!',
            isVerifiedPurchase: true,
            createdAt: DateTime.now().subtract(Duration(days: index)),
          ),
        );

        _productReviews = List.generate(
          8,
          (index) => Review(
            id: 'product_review_$index',
            userId: 'user_$index',
            productId: 'current_product',
            rating: 3 + (index % 3),
            title: index % 2 == 0 ? 'Amazing quality!' : null,
            comment: 'Really happy with this purchase. Will buy again.',
            images: index % 3 == 0 ? ['image1.jpg', 'image2.jpg'] : null,
            isVerifiedPurchase: index % 2 == 0,
            createdAt: DateTime.now().subtract(Duration(days: index * 2)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reviews: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Review> _getFilteredReviews(List<Review> reviews) {
    switch (_selectedFilter) {
      case '5_star':
        return reviews.where((r) => r.rating == 5).toList();
      case '4_star':
        return reviews.where((r) => r.rating == 4).toList();
      case '3_star':
        return reviews.where((r) => r.rating == 3).toList();
      case '2_star':
        return reviews.where((r) => r.rating == 2).toList();
      case '1_star':
        return reviews.where((r) => r.rating == 1).toList();
      case 'with_photos':
        return reviews.where((r) => r.hasImages).toList();
      case 'verified':
        return reviews.where((r) => r.isVerifiedPurchase).toList();
      default:
        return reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const GlassyAppBar(title: 'Reviews'),
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
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: const [
                  Tab(text: 'My Reviews'),
                  Tab(text: 'Product Reviews'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.blueAccent,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMyReviewsTab(),
                    _buildProductReviewsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyReviewsTab() {
    final filteredReviews = _getFilteredReviews(_myReviews);

    return Column(
      children: [
        // Filter Chips
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('5 ★', '5_star'),
              _buildFilterChip('4 ★', '4_star'),
              _buildFilterChip('3 ★', '3_star'),
              _buildFilterChip('With Photos', 'with_photos'),
              _buildFilterChip('Verified', 'verified'),
            ],
          ),
        ),

        // Reviews List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredReviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your reviews will appear here',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredReviews.length,
                      itemBuilder: (context, index) {
                        return _buildReviewCard(filteredReviews[index], isMyReview: true);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProductReviewsTab() {
    final filteredReviews = _getFilteredReviews(_productReviews);

    return Column(
      children: [
        // Review Stats
        GlassyContainer(
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${_productReviews.length}',
                'Total Reviews',
                Icons.reviews,
              ),
              _buildStatItem(
                '4.2',
                'Average Rating',
                Icons.star,
              ),
              _buildStatItem(
                '85%',
                'Recommended',
                Icons.thumb_up,
              ),
            ],
          ),
        ),

        // Filter Chips
        Container(
          height: 50,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('5 ★', '5_star'),
              _buildFilterChip('4 ★', '4_star'),
              _buildFilterChip('3 ★', '3_star'),
              _buildFilterChip('With Photos', 'with_photos'),
              _buildFilterChip('Verified', 'verified'),
            ],
          ),
        ),

        // Reviews List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(filteredReviews[index], isMyReview: false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = selected ? filter : 'all');
        },
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        selectedColor: Colors.blueAccent,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review, {required bool isMyReview}) {
    return GlassyContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Text(
                    isMyReview ? 'You' : 'U${review.userId.substring(0, 2).toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // User Info & Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMyReview ? 'You' : 'User ${review.userId.substring(0, 8)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Date & Verification
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (review.isVerifiedPurchase)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Review Title
            if (review.title != null) ...[
              Text(
                review.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Review Comment
            Text(
              review.comment,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Review Images
            if (review.hasImages) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white24,
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.white54,
                      ),
                    );
                  },
                ),
              ),
            ],

            // Actions (only for my reviews)
            if (isMyReview) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Edit review
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Delete review
                      _showDeleteReviewDialog(review);
                    },
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteReviewDialog(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Delete Review', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this review?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete review logic
              setState(() {
                _myReviews.remove(review);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}