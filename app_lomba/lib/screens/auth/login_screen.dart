import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_lomba/services/auth_service.dart';
import 'package:app_lomba/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError('Email dan password wajib diisi.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final role = await AuthService().loginWithEmail(email, password);
      if (role == 'panitia') {
        Navigator.pushReplacementNamed(context, Routes.panitiaDashboard);
      } else if (role == 'peserta') {
        Navigator.pushReplacementNamed(context, Routes.pesertaDashboard);
      } else {
        showError('Role pengguna tidak dikenali.');
      }
    } on FirebaseAuthException catch (e) {
      final Map<String, String> map = {
        'user-not-found': 'Email tidak ditemukan. Silakan daftar terlebih dahulu.',
        'wrong-password': 'Password salah. Silakan coba lagi.',
        'invalid-email': 'Format email tidak valid.',
        'too-many-requests': 'Terlalu banyak percobaan. Coba beberapa saat lagi.',
        'user-not-found-in-firestore':
            'Akun ini belum melengkapi data. Hubungi admin.',
      };
      showError(map[e.code] ?? 'Login gagal: ${e.message}');
    } catch (e) {
      showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void navigateToRegister() =>
      Navigator.pushReplacementNamed(context, Routes.register);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lomba Kicau Mania',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email', Icons.email),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('Password', Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: login,
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text('Login',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
              TextButton(
                onPressed: navigateToRegister,
                child: const Text('Belum punya akun? Daftar di sini'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
