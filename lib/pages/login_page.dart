// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import '../services/service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _service = AppService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _service.loginUser(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.people_alt_rounded, size: 72, color: Colors.deepPurple),
              const SizedBox(height: 12),
              const Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 28),
              _field(_emailCtrl, 'Email', Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_passCtrl, 'Password', Icons.lock, obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}