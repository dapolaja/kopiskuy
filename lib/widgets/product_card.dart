import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import '../core/services/api_service.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String role = "user";

  final Color primaryColor = const Color(0xFF6F4E37);

  @override
  void initState() {
    super.initState();
    getRole();
  }

  Future<void> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString("role") ?? "user";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260, // ✅ FIX overflow (tinggi card tetap)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // 📷 IMAGE + ADMIN ACTION
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: widget.product.image != null
                    ? Image.network(
                        "http://192.168.1.16:3000/uploads/${widget.product.image}",
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 110,
                            child: Icon(Icons.image_not_supported),
                          );
                        },
                      )
                    : const SizedBox(height: 110, child: Icon(Icons.image)),
              ),

              // 🔧 ADMIN BUTTONS
              if (role == "admin")
                Positioned(
                  right: 5,
                  top: 5,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => showEditDialog(context),
                        child: const CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, size: 15, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: () async {
                          await ApiService().deleteProduct(widget.product.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Produk dihapus")),
                          );
                          setState(() {});
                        },
                        child: const CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.delete,
                            size: 15,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // 📦 CONTENT (pakai Expanded biar aman)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷 NAMA
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // 💰 HARGA
                  Text(
                    "Rp ${widget.product.price}",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // ⭐ RATING
                  Row(
                    children: const [
                      Icon(Icons.star, size: 12, color: Colors.orange),
                      Icon(Icons.star, size: 12, color: Colors.orange),
                      Icon(Icons.star, size: 12, color: Colors.orange),
                      Icon(Icons.star_half, size: 12, color: Colors.orange),
                      Icon(Icons.star_border, size: 12, color: Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // 📦 STOK
                  Text(
                    "Stok: ${widget.product.stock}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),

                  const Spacer(), 
                  // 🛒 BUTTON USER
                  if (role != "admin")
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ApiService().addToCart(widget.product.id, 1);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Berhasil ditambahkan ke cart"),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Tambah",
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✏️ EDIT DIALOG
  void showEditDialog(BuildContext context) {
    final name = TextEditingController(text: widget.product.name);
    final price = TextEditingController(text: widget.product.price.toString());
    final stock = TextEditingController(text: widget.product.stock.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Produk"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: price,
              decoration: const InputDecoration(labelText: "Harga"),
            ),
            TextField(
              controller: stock,
              decoration: const InputDecoration(labelText: "Stock"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService().updateProduct(widget.product.id, {
                "name": name.text,
                "price": price.text,
                "stock": stock.text,
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Produk diupdate")));

              setState(() {});
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}
