class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;
  final String? category;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stock,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sellerId: json['seller_id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      imageUrl: json['image_url'],
      stock: json['stock'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'stock': stock,
      'category': category,
    };
  }
}