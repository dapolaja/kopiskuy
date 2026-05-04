import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  final api = ApiService();

  bool isLoading = false;

  // 🎨 warna kopi (samakan dengan login)
  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFD7CCC8);

  Future<void> register() async {
    if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await api.dio.post(
        '/register',
        data: {
          "name": name.text,
          "email": email.text,
          "password": password.text,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register berhasil")));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register gagal")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 🎬 LOTTIE (pakai asset yang sama biar konsisten)
              SizedBox(
                height: 180,
                child: Lottie.asset(
                  'assets/lottie/coffee1.json',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "REGISTER",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 30),

              // 👤 NAME
              TextField(
                controller: name,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Nama",
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 📧 EMAIL
              TextField(
                controller: email,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 🔒 PASSWORD
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔘 REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 10),

              // 🔙 BACK TO LOGIN
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Sudah punya akun? Login",
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
