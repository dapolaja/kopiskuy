import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class VoucherService {
  static Future<String> _getVoucherKey() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt("user_id");

    return "vouchers_$userId";
  }

  static Future<String> generateVoucher() async {
    final rnd = Random();

    final rewards = [
      "Diskon 5%",
      "Diskon 10%",
    ];

    final reward = rewards[rnd.nextInt(rewards.length)];
    final prefs = await SharedPreferences.getInstance();
    final vouchers = await getVouchers();
    vouchers.add(reward);
    final key = await _getVoucherKey();
    await prefs.setString(
      key,
      jsonEncode(vouchers),
    );
    return reward;
  }

  static Future<List<String>> getVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getVoucherKey();
    final data = prefs.getString(key);
    if (data == null) return [];
    return List<String>.from(
      jsonDecode(data),
    );
  }

  static Future<void> removeVoucher(
    String voucher,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final vouchers = await getVouchers();
    vouchers.remove(voucher);
    final key = await _getVoucherKey();
    await prefs.setString(
      key,
      jsonEncode(vouchers),
    );
  }

  static Future<void> clearVoucher() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getVoucherKey();
    await prefs.remove(key);
  }
}
