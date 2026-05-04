class Product {
  final int id;
  final String name;
  final int price;
  final int stock;
  final String? image;
  final String? description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.image,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      stock: json['stock'],
      image: json['image'],
      description: json['description'],
    );
  }
}