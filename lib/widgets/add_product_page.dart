import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../core/services/api_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final name = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController();
  final description = TextEditingController();

  final api = ApiService();

  File? imageFile;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  Future<void> addProduct() async {
    if (name.text.isEmpty ||
        price.text.isEmpty ||
        stock.text.isEmpty ||
        description.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }

    if (imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih gambar dulu")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔥 WAJIB: set token dulu
      await api.setAuthHeader();

      FormData formData = FormData.fromMap({
        "name": name.text,
        "price": price.text,
        "stock": stock.text,
        "description": description.text,
        "image": await MultipartFile.fromFile(
          imageFile!.path,
          filename: imageFile!.path.split('/').last,
        ),
      });

      final response = await api.dio.post(
        '/products',
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );

      print("SUCCESS: ${response.data}");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produk berhasil ditambahkan")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("ERROR UPLOAD: $e");

      if (e is DioException) {
        print("RESPONSE: ${e.response?.data}");
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal upload")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Kopi")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: "Nama Kopi"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Harga"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stock"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Deskripsi"),
              ),

              const SizedBox(height: 20),

              imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        imageFile!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Text("Belum pilih gambar"),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Pilih Gambar"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : addProduct,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
