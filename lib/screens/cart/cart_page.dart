import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final api = ApiService();

  List cart = [];
  bool isLoading = true;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFD7CCC8);

  @override
  void initState() {
    super.initState();
    getCart();
  }

  Future<void> getCart() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");

      if (userId == null) {
        setState(() {
          cart = [];
          isLoading = false;
        });
        return;
      }

      final data = await api.getCart(userId);

      if (!mounted) return;

      setState(() {
        cart = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal load cart")));
    }
  }

  int getTotal() {
    int total = 0;
    for (var item in cart) {
      total += (item["price"] as int) * (item["qty"] as int);
    }
    return total;
  }

  Future<void> checkout() async {
    try {
      final res = await api.checkout();

      if (!mounted) return;

      await NotificationService.showNotification(
        title: "Checkout Berhasil ☕",
        body: "Pesanan kamu sedang diproses",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Checkout berhasil")),
      );

      getCart();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Checkout gagal")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        title: const Text("Keranjang"),
        backgroundColor: primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: getCart,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : cart.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 200),
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Keranjang kosong",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  // ===== LIST CART =====
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 6,
                                color: Colors.black12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.local_cafe,
                                color: primaryColor,
                              ),
                            ),
                            title: Text(
                              item["name"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Qty: ${item["qty"]}"),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Rp ${item["price"]}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Total: Rp ${item["price"] * item["qty"]}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ===== TOTAL + CHECKOUT =====
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Pembayaran",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              "Rp ${getTotal()}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: checkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Checkout",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
