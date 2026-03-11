import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _auth = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const Color _primary = Color(0xFF25343F);
  static const Color _secondary = Color(0xFF3A4F5E);
  static const Color _muted = Color(0xFFBFC9D1);
  static const Color _background = Color(0xFFEAEFEF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _auth.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully'),
          backgroundColor: _primary,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_primary, _secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign up to get started",
                  style: TextStyle(
                    color: _secondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode:
                        AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        _buildInputField(
                          "Full Name",
                          _nameController,
                          Icons.person,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          "Email",
                          _emailController,
                          Icons.email_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          "Password",
                          _passwordController,
                          Icons.lock_rounded,
                          obscure: _obscurePassword,
                          toggle: () => setState(() =>
                              _obscurePassword =
                                  !_obscurePassword),
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          "Confirm Password",
                          _confirmPasswordController,
                          Icons.lock_person_rounded,
                          obscure: _obscureConfirm,
                          toggle: () => setState(() =>
                              _obscureConfirm =
                                  !_obscureConfirm),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor:
                                  Colors.white,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        16),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "CREATE ACCOUNT",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LoginPage()),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style:
                          TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(
                            color: _primary,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggle,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textInputAction: TextInputAction.next,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please enter $label';
        }
        if (label == "Email" &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(v)) {
          return 'Enter a valid email';
        }
        if (label == "Password" && v.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (label == "Confirm Password" &&
            v != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: _secondary),
        filled: true,
        fillColor: Colors.white,
        prefixIcon:
            Icon(icon, color: _secondary),
        suffixIcon: toggle != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: _secondary,
                ),
                onPressed: toggle,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
              color: _muted.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: _primary, width: 2),
        ),
      ),
    );
  }
}