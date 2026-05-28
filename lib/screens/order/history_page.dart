import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/currency_service.dart';
import 'detail_order_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final api = ApiService();

  List history = [];
  bool isLoading = true;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFF5F1EE);

  @override
  void initState() {
    super.initState();

    CurrencyService.instance.addListener(refreshCurrency);

    getHistory();
  }

  void refreshCurrency() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CurrencyService.instance.removeListener(refreshCurrency);
    super.dispose();
  }

  Future<void> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");

      if (userId == null) {
        setState(() {
          history = [];
          isLoading = false;
        });
        return;
      }

      final data = await api.getHistory(userId);

      if (!mounted) return;

      setState(() {
        history = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal load riwayat pesanan"),
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "success":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancel":
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "success":
        return Icons.check_circle_rounded;
      case "pending":
        return Icons.access_time_filled_rounded;
      case "cancel":
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: accentColor,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          "Riwayat Pesanan",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : history.isEmpty
              ? const Center(
                  child: Text("Belum ada pesanan"),
                )
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: getHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ...history.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        final status = (item["status"] ?? "pending").toString();

                        final orderNumber = index + 1;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailOrderPage(
                                  orderId: item["id"],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                  color: Colors.black.withOpacity(0.05),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        primaryColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.local_cafe_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Order #$orderNumber",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      // FIXED CONVERT
                                      Text(
                                        CurrencyService.instance.format(
                                          item["total"],
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(status)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              getStatusIcon(status),
                                              size: 14,
                                              color: getStatusColor(status),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: getStatusColor(status),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }
}
