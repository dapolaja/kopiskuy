import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends ChangeNotifier {
  // =========================
  // SINGLETON
  // =========================
  static final CurrencyService instance = CurrencyService._internal();

  CurrencyService._internal();

  // =========================
  // STATE
  // =========================
  String selectedCurrency = "IDR";

  final Map<String, double> rates = {
    "IDR": 1,
    "USD": 0.000061,
    "MYR": 0.00029,
    "EUR": 0.000057,
  };

  // =========================
  // INIT
  // =========================
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    selectedCurrency = prefs.getString("currency") ?? "IDR";

    await fetchRates();
  }

  // =========================
  // FETCH LIVE RATE
  // =========================
  Future<void> fetchRates() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://api.exchangerate-api.com/v4/latest/IDR",
        ),
      );

      final data = jsonDecode(response.body);
      rates["USD"] = (data["rates"]["USD"] as num).toDouble();
      rates["MYR"] = (data["rates"]["MYR"] as num).toDouble();
      rates["EUR"] = (data["rates"]["EUR"] as num).toDouble();

      notifyListeners();
    } catch (_) {}
  }

  // =========================
  // CHANGE CURRENCY
  // =========================
  Future<void> changeCurrency(String currency) async {
    selectedCurrency = currency;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "currency",
      currency,
    );

    notifyListeners();
  }

  // =========================
  // CONVERT
  // =========================
  double convert(num idr) {
    return idr * (rates[selectedCurrency] ?? 1);
  }

  // =========================
  // FORMAT
  // =========================
  String format(num idr) {
    final value = convert(idr);

    switch (selectedCurrency) {
      case "USD":
        return "\$${value.toStringAsFixed(2)}";

      case "MYR":
        return "RM${value.toStringAsFixed(2)}";

      case "EUR":
        return "€${value.toStringAsFixed(2)}";

      default:
        return "Rp ${idr.toStringAsFixed(0)}";
    }
  }
}
