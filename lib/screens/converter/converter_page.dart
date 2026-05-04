import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final api = ApiService();
  final controller = TextEditingController();

  double idr = 0;
  double usd = 0;
  double myr = 0;
  double eur = 0;

  bool isLoading = true;

  DateTime now = DateTime.now();
  Timer? timer;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFD7CCC8);

  @override
  void initState() {
    super.initState();
    getRates();
    startClock();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> getRates() async {
    try {
      final data = await api.getRates();

      setState(() {
        usd = data["rates"]["USD"];
        myr = data["rates"]["MYR"];
        eur = data["rates"]["EUR"];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ⏰ CLOCK
  void startClock() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:"
        "${time.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======================
                  // 💱 HEADER CARD
                  // ======================
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.currency_exchange,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Currency Converter",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 💱 INPUT
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Masukkan Rupiah (IDR)",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.money, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        idr = double.tryParse(value) ?? 0;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // 💱 RESULT CARD
                  buildCurrencyCard(
                    "USD",
                    "\$ ${(idr * usd).toStringAsFixed(2)}",
                  ),
                  buildCurrencyCard(
                    "MYR",
                    "RM ${(idr * myr).toStringAsFixed(2)}",
                  ),
                  buildCurrencyCard(
                    "EUR",
                    "€ ${(idr * eur).toStringAsFixed(2)}",
                  ),

                  const SizedBox(height: 25),

                  // ======================
                  // ⏰ TIME HEADER
                  // ======================
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.access_time, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Time Converter",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  buildTimeCard("WIB (UTC+7)", now),
                  buildTimeCard(
                    "WITA (UTC+8)",
                    now.add(const Duration(hours: 1)),
                  ),
                  buildTimeCard(
                    "WIT (UTC+9)",
                    now.add(const Duration(hours: 2)),
                  ),
                  buildTimeCard(
                    "London (UTC+0)",
                    now.subtract(const Duration(hours: 7)),
                  ),
                ],
              ),
            ),
    );
  }

  // 💱 CURRENCY CARD
  Widget buildCurrencyCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ],
      ),
    );
  }

  // ⏰ TIME CARD
  Widget buildTimeCard(String title, DateTime time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            formatTime(time),
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
