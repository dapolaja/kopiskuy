import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class DetailOrderPage extends StatefulWidget {
  final int orderId;

  const DetailOrderPage({super.key, required this.orderId});

  @override
  State<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends State<DetailOrderPage> {
  final api = ApiService();

  List items = [];
  bool isLoading = true;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFD7CCC8);

  @override
  void initState() {
    super.initState();
    getDetail();
  }

  Future<void> getDetail() async {
    try {
      final data = await api.getDetailOrder(widget.orderId);

      if (!mounted) return;

      setState(() {
        items = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal load detail order")));
    }
  }

  int getTotal() {
    int total = 0;
    for (var item in items) {
      total += (item["price"] as int) * (item["qty"] as int);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        title: Text("Order #${widget.orderId}"),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ======================
                // 📦 LIST ITEM
                // ======================
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
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
                        child: Row(
                          children: [
                            // ICON
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.local_cafe,
                                color: primaryColor,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // DETAIL
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["name"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Qty: ${item["qty"]}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // PRICE
                            Text(
                              "Rp ${item["price"]}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ======================
                // 💰 TOTAL + ACTION
                // ======================
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(blurRadius: 8, color: Colors.grey.shade300),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total", style: TextStyle(fontSize: 16)),
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

                      const SizedBox(height: 10),

                      // 🔁 REORDER BUTTON (bonus UX)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Fitur repeat order coming soon"),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Pesan Lagi",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
