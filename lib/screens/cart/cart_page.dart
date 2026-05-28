import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../storage/voucher_service.dart';
import '../../core/services/currency_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final api = ApiService();

  List cart = [];

  bool isLoading = true;

  List<String> vouchers = [];
  String? selectedVoucher;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFF5F1EE);

  @override
  void initState() {
    super.initState();
    CurrencyService.instance.selectedCurrency;
    getCart();
    getVouchers();
  }

  Future<void> getVouchers() async {
    final data = await VoucherService.getVouchers();

    setState(() {
      vouchers = data.toSet().toList();
    });
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memuat keranjang"),
        ),
      );
    }
  }

  int getTotal() {
    int total = 0;

    for (var item in cart) {
      total += (item["price"] as int) * (item["qty"] as int);
    }

    return total;
  }

  int getDiscount() {
    final total = getTotal();

    if (selectedVoucher == null) return 0;

    if (selectedVoucher == "Diskon 5%") {
      return (total * 0.05).toInt();
    }

    if (selectedVoucher == "Diskon 10%") {
      return (total * 0.10).toInt();
    }

    if (selectedVoucher == "Gratis Kopi") {
      return 15000;
    }

    return 0;
  }

  int getFinalTotal() {
    final total = getTotal() - getDiscount();

    if (total < 0) return 0;

    return total;
  }

  Future<void> updateQty(int cartId, int qty) async {
    try {
      await api.updateCartQty(cartId, qty);

      getCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal update quantity"),
        ),
      );
    }
  }

  Future<void> checkout() async {
    try {
      final res = await api.checkout(
        voucherName: selectedVoucher,
      );

      if (selectedVoucher != null) {
        await VoucherService.removeVoucher(
          selectedVoucher!,
        );
      }

      if (!mounted) return;

      await NotificationService.showNotification(
        title: "Checkout Berhasil ☕",
        body: "Pesanan kamu sedang diproses",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res["message"] ?? "Checkout berhasil",
          ),
        ),
      );

      setState(() {
        selectedVoucher = null;
      });

      getCart();
      getVouchers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Checkout gagal"),
        ),
      );
    }
  }

  Widget qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          icon,
          size: 18,
          color: primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: accentColor,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          "Keranjang",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: getCart,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              )
            : cart.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 180),
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 90,
                        color: Colors.brown.shade300,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Keranjang masih kosong",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Yuk mulai pesan kopi favoritmu ☕",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // =========================
                      // CART LIST
                      // =========================
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.length,
                          itemBuilder: (context, index) {
                            final item = cart[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 65,
                                    height: 65,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      Icons.local_cafe,
                                      size: 34,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["name"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            qtyButton(
                                              icon: Icons.remove,
                                              onTap: () {
                                                updateQty(
                                                  item["id"],
                                                  item["qty"] - 1,
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              "${item["qty"]}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            qtyButton(
                                              icon: Icons.add,
                                              onTap: () {
                                                updateQty(
                                                  item["id"],
                                                  item["qty"] + 1,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyService.instance
                                            .format(item["price"]),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        CurrencyService.instance.format(
                                          item["price"] * item["qty"],
                                        ),
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // =========================
                      // BOTTOM CHECKOUT
                      // =========================
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (vouchers.isNotEmpty) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Voucher Tersedia",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: vouchers.contains(selectedVoucher)
                                    ? selectedVoucher
                                    : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: accentColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text("Pilih voucher"),
                                items: vouchers.map((voucher) {
                                  return DropdownMenuItem<String>(
                                    value: voucher,
                                    child: Text(voucher),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedVoucher = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Subtotal",
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  CurrencyService.instance.format(getTotal()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Diskon",
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  "- ${CurrencyService.instance.format(getDiscount())}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Pembayaran",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  CurrencyService.instance
                                      .format(getFinalTotal()),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: checkout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  "Checkout Sekarang",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
