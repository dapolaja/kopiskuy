import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class VoucherService {
  static Future<String> generateVoucher() async {
    final rnd = Random();
    final rewards = ["Diskon 5%", "Diskon 10%", "Gratis Kopi"];

    final reward = rewards[rnd.nextInt(rewards.length)];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("voucher", reward);

    return reward;
  }

  static Future<String?> getVoucher() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("voucher");
  }

  static Future<void> clearVoucher() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("voucher");
  }
}
