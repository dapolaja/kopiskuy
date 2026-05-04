import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../storage/voucher_service.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({super.key});

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage> {
  int shakeCount = 0;
  bool isPlaying = false;
  String result = "";

  final int targetShake = 15;
  StreamSubscription? _subscription;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFD7CCC8);

  void startGame() {
    shakeCount = 0;
    result = "";
    isPlaying = true;

    _subscription = accelerometerEvents.listen((event) async {
      double force =
          (event.x * event.x + event.y * event.y + event.z * event.z);

      if (force > 150) {
        shakeCount++;

        if (shakeCount >= targetShake) {
          await winGame();
        }

        setState(() {});
      }
    });

    setState(() {});
  }

  Future<void> winGame() async {
    _subscription?.cancel();
    isPlaying = false;

    final reward = await VoucherService.generateVoucher();

    result = "🎉 Kamu dapat:\n$reward";

    setState(() {});
  }

  void stopGame() {
    _subscription?.cancel();
    isPlaying = false;

    setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = shakeCount / targetShake;

    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ☕ ICON
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.local_cafe,
                    size: 50,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Shake Coffee Game",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Goyangkan HP kamu untuk mendapatkan voucher!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // 🔢 COUNTER
                Text(
                  "$shakeCount / $targetShake",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 15),

                // 📊 PROGRESS
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.7
                          ? Colors.green
                          : primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🎮 BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isPlaying ? stopGame : startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPlaying ? Colors.red : primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      isPlaying ? "Stop Game" : "Mulai Game",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🎁 RESULT
                if (result.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}