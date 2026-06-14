import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/product_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  late Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: "http://192.168.100.84:3000/api",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ),
    );
  }

  Future<Options> authOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    print("TOKEN => $token");

    if (token == null || token.isEmpty) {
      throw Exception("Token tidak ditemukan");
    }

    return Options(
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );
  }

  Future<List<Product>> getProducts() async {
    final response = await dio.get(
      '/products',
    );

    List data = response.data;

    return data.map((e) => Product.fromJson(e)).toList();
  }

  Future<void> addToCart(
    int productId,
    int qty, {
    String? size,
    String? temp,
  }) async {
    final response = await dio.post(
      '/cart',
      data: {
        "product_id": productId,
        "qty": qty,
        "size": size,
        "temp": temp,
      },
      options: await authOptions(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Gagal tambah cart",
      );
    }
  }

  Future<List> getCart(
    int userId,
  ) async {
    final response = await dio.get(
      '/cart/$userId',
      options: await authOptions(),
    );

    return response.data;
  }

  Future<void> updateCartQty(
    int cartId,
    int qty,
  ) async {
    await dio.put(
      '/cart/$cartId',
      data: {
        "qty": qty,
      },
      options: await authOptions(),
    );
  }

  Future<void> removeFromCart(int cartId) async {
    await dio.delete(
      '/cart/$cartId',
      options: await authOptions(),
    );
  }

  Future<Map<String, dynamic>> checkout({
    String? voucherName,
  }) async {
    final response = await dio.post(
      '/order',
      data: {
        "voucher": voucherName,
      },
      options: await authOptions(),
    );

    return response.data;
  }

  Future<List> getHistory(
    int userId,
  ) async {
    final response = await dio.get(
      '/history/$userId',
      options: await authOptions(),
    );

    return response.data;
  }

  Future<List> getDetailOrder(
    int orderId,
  ) async {
    final response = await dio.get(
      '/order/$orderId',
      options: await authOptions(),
    );

    return response.data;
  }

  Future<List> getAllOrders() async {
    final response = await dio.get(
      '/all-orders',
      options: await authOptions(),
    );

    return response.data;
  }

  Future<void> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    await dio.put(
      '/order/status/$orderId',
      data: {
        "status": status,
      },
      options: await authOptions(),
    );
  }

  Future<List> getRecommendation() async {
    final response = await dio.get(
      '/recommendation',
      options: await authOptions(),
    );

    return response.data;
  }

  Future<void> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    await dio.put(
      '/products/$id',
      data: data,
      options: await authOptions(),
    );
  }

  Future<void> deleteProduct(
    int id,
  ) async {
    await dio.delete(
      '/products/$id',
      options: await authOptions(),
    );
  }

  Future<Map<String, dynamic>> getRates() async {
    final response = await dio.get(
      'https://api.exchangerate-api.com/v4/latest/IDR',
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getLatestRates(String base) async {
    final response = await dio.get(
      'https://api.exchangerate-api.com/v4/latest/$base',
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getCoffeePrediction(
    double idr,
  ) async {
    final rates = await getRates();
    final usd = idr * rates["rates"]["USD"];
    final myr = idr * rates["rates"]["MYR"];
    final eur = idr * rates["rates"]["EUR"];

    return {
      "USD": usd,
      "MYR": myr,
      "EUR": eur,
    };
  }
}
