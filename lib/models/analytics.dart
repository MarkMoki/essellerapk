class AnalyticsData {
  final String id;
  final String sellerId;
  final DateTime date;
  final int totalOrders;
  final double totalRevenue;
  final int totalProductsSold;
  final int uniqueCustomers;
  final double averageOrderValue;
  final Map<String, int> productSales; // product_id -> quantity sold
  final Map<String, double> categoryRevenue; // category -> revenue
  final DateTime createdAt;
  final DateTime? updatedAt;

  AnalyticsData({
    required this.id,
    required this.sellerId,
    required this.date,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalProductsSold,
    required this.uniqueCustomers,
    required this.averageOrderValue,
    required this.productSales,
    required this.categoryRevenue,
    required this.createdAt,
    this.updatedAt,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      id: json['id'],
      sellerId: json['seller_id'],
      date: DateTime.parse(json['date']),
      totalOrders: json['total_orders'],
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalProductsSold: json['total_products_sold'],
      uniqueCustomers: json['unique_customers'],
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
      productSales: Map<String, int>.from(json['product_sales'] ?? {}),
      categoryRevenue: Map<String, double>.from(json['category_revenue'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'date': date.toIso8601String(),
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'total_products_sold': totalProductsSold,
      'unique_customers': uniqueCustomers,
      'average_order_value': averageOrderValue,
      'product_sales': productSales,
      'category_revenue': categoryRevenue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AnalyticsData copyWith({
    int? totalOrders,
    double? totalRevenue,
    int? totalProductsSold,
    int? uniqueCustomers,
    double? averageOrderValue,
    Map<String, int>? productSales,
    Map<String, double>? categoryRevenue,
    DateTime? updatedAt,
  }) {
    return AnalyticsData(
      id: id,
      sellerId: sellerId,
      date: date,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalProductsSold: totalProductsSold ?? this.totalProductsSold,
      uniqueCustomers: uniqueCustomers ?? this.uniqueCustomers,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      productSales: productSales ?? this.productSales,
      categoryRevenue: categoryRevenue ?? this.categoryRevenue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AnalyticsSummary {
  final String sellerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalOrders;
  final double totalRevenue;
  final double growthRate; // percentage
  final int newCustomers;
  final double customerRetentionRate;
  final Map<String, double> topProducts; // product_name -> revenue
  final Map<String, double> topCategories; // category -> revenue

  AnalyticsSummary({
    required this.sellerId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalOrders,
    required this.totalRevenue,
    required this.growthRate,
    required this.newCustomers,
    required this.customerRetentionRate,
    required this.topProducts,
    required this.topCategories,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      sellerId: json['seller_id'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      totalOrders: json['total_orders'],
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      growthRate: (json['growth_rate'] as num).toDouble(),
      newCustomers: json['new_customers'],
      customerRetentionRate: (json['customer_retention_rate'] as num).toDouble(),
      topProducts: Map<String, double>.from(json['top_products'] ?? {}),
      topCategories: Map<String, double>.from(json['top_categories'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'growth_rate': growthRate,
      'new_customers': newCustomers,
      'customer_retention_rate': customerRetentionRate,
      'top_products': topProducts,
      'top_categories': topCategories,
    };
  }
}