import 'package:dio/dio.dart';
import '../../models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.1.16:3000/api",
      headers: {"Content-Type": "application/json"},
    ),
  );

  Future<void> setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  Future<void> addToCart(int productId, int qty) async {
    await setAuthHeader();
    final response = await dio.post(
      '/cart',
      data: {"product_id": productId, "qty": qty},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Gagal tambah cart");
    }
  }

  Future<List<Product>> getProducts() async {
    await setAuthHeader();
    final response = await dio.get('/products');
    List data = response.data;
    return data.map((e) => Product.fromJson(e)).toList();
  }

  Future<List> getCart(int userId) async {
    await setAuthHeader();
    final response = await dio.get('/cart/$userId');
    return response.data;
  }

  Future<Map<String, dynamic>> checkout() async {
    await setAuthHeader();
    final response = await dio.post('/order');
    return response.data;
  }

  Future<List> getHistory(int userId) async {
    await setAuthHeader();
    final response = await dio.get('/history/$userId');
    return response.data;
  }

  Future<List> getDetailOrder(int orderId) async {
    await setAuthHeader();
    final response = await dio.get('/order/$orderId');
    return response.data;
  }

  Future<List> getRecommendation() async {
    await setAuthHeader();
    final response = await dio.get('/recommendation');
    return response.data;
  }

  Future<Map<String, dynamic>> getRates() async {
    final response = await dio.get(
      'https://api.exchangerate-api.com/v4/latest/IDR',
    );
    return response.data;
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    await setAuthHeader();
    await dio.put('/products/$id', data: data);
  }

  Future<void> deleteProduct(int id) async {
    await setAuthHeader();
    await dio.delete('/products/$id');
  }
}
