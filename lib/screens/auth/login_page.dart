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
  bool obscurePassword = true;

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFF5F1EE);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void showCustomSnackbar({
    required String title,
    required String message,
    required Color color,
    IconData icon = Icons.info_outline,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.all(14),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> login() async {
    if (email.text.trim().isEmpty) {
      showCustomSnackbar(
        title: "Validation Error",
        message: "Email tidak boleh kosong",
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (password.text.trim().isEmpty) {
      showCustomSnackbar(
        title: "Validation Error",
        message: "Password tidak boleh kosong",
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await api.dio.post(
        '/login',
        data: {
          "email": email.text.trim(),
          "password": password.text.trim(),
        },
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        "token",
        response.data["token"],
      );

      await prefs.setInt(
        "user_id",
        response.data["user"]["id"],
      );

      await prefs.setString(
        "email",
        response.data["user"]["email"],
      );

      await prefs.setString(
        "role",
        response.data["user"]["role"] ?? "user",
      );

      // aktif setelah login manual
      await prefs.setBool(
        "biometric_enabled",
        true,
      );

      showCustomSnackbar(
        title: "Success",
        message: "Login berhasil",
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      showCustomSnackbar(
        title: "Login Failed",
        message: "Email atau password salah",
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> biometricLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool("biometric_enabled") ?? false;

    if (!enabled) {
      showCustomSnackbar(
        title: "Fingerprint Belum Aktif",
        message: "Login manual terlebih dahulu",
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    final biometric = BiometricService();

    final available = await biometric.isAvailable();

    if (!available) {
      showCustomSnackbar(
        title: "Fingerprint Tidak Tersedia",
        message: "Device tidak mendukung biometric",
        color: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    final success = await biometric.authenticate();

    if (!mounted) return;

    if (success) {
      showCustomSnackbar(
        title: "Login Berhasil",
        message: "Berhasil login menggunakan fingerprint",
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } else {
      showCustomSnackbar(
        title: "Autentikasi Gagal",
        message: "Fingerprint tidak dikenali",
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Lottie.asset(
                'assets/lottie/coffee1.json',
                height: 220,
              ),

              const SizedBox(height: 10),

              Text(
                "KOPISKUY",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Nikmati kopi favoritmu kapan saja",
                style: TextStyle(
                  color: Colors.brown.shade400,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // EMAIL
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: accentColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // PASSWORD
                    TextField(
                      controller: password,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: primaryColor,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: primaryColor,
                          ),
                        ),
                        filled: true,
                        fillColor: accentColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              18,
                            ),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // FINGERPRINT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: biometricLogin,
                        icon: Icon(
                          Icons.fingerprint,
                          color: primaryColor,
                        ),
                        label: Text(
                          "Login dengan Fingerprint",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: primaryColor.withOpacity(
                              0.3,
                            ),
                          ),
                          backgroundColor: primaryColor.withOpacity(
                            0.03,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // REGISTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Belum punya akun?",
                  ),
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
                      "Register",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
