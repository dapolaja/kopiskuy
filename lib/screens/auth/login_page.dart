import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/biometric_service.dart';

import '../home/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  final api = ApiService();

  bool isLoading = false;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFD7CCC8);

  @override
  void initState() {
    super.initState();
    autoBiometric();
  }

  Future<void> autoBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool("biometric_enabled");

    if (enabled == true) {
      final biometric = BiometricService();
      bool success = await biometric.authenticate();

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    }
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final response = await api.dio.post(
        '/login',
        data: {"email": email.text, "password": password.text},
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", response.data["token"]);
      await prefs.setInt("user_id", response.data["user"]["id"]);
      await prefs.setBool("biometric_enabled", true);
      await prefs.setString("email", response.data["user"]["email"]);
      await prefs.setString("role", response.data["user"]["role"] ?? "user");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login gagal")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> biometricLogin() async {
    final biometric = BiometricService();

    bool available = await biometric.isAvailable();

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometric tidak tersedia")),
      );
      return;
    }

    bool success = await biometric.authenticate();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
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

              // 🎬 LOTTIE
              Lottie.asset('assets/lottie/coffee1.json', height: 200),

              const SizedBox(height: 10),

              Text(
                "KOPISKUY",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 30),

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

              // 🔘 LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔐 BIOMETRIC
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: biometricLogin,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("Login dengan Fingerprint"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 📝 REGISTER
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
                child: Text(
                  "Belum punya akun? Register",
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