import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Map<String, dynamic>? userData;
  bool _isLoading = false;
  bool _isFetching = true;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  static const Color _primary = Color(0xFF25343F);
  static const Color _secondary = Color(0xFF3A4F5E);
  static const Color _muted = Color(0xFFBFC9D1);
  static const Color _background = Color(0xFFEAEFEF);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await _auth.getProfile();
    if (mounted) {
      setState(() {
        userData = data;
        _nameController.text = data?['name'] ?? '';
        _isFetching = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await _auth.updateProfile(
      name: _nameController.text.trim(),
      currentPassword: _currentPasswordController.text.isNotEmpty
          ? _currentPasswordController.text
          : null,
      newPassword: _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: _primary,
        ),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
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
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isFetching
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: Text(
                              _getInitials(userData?['name'] ?? ''),
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData?['name'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userData?['email'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Profile Information",
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      "Full Name",
                      _nameController,
                      Icons.person,
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Security",
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      "Current Password",
                      _currentPasswordController,
                      Icons.lock_clock_rounded,
                      obscure: _obscureCurrent,
                      toggle: () => setState(
                          () => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      "New Password",
                      _newPasswordController,
                      Icons.vpn_key_rounded,
                      obscure: _obscureNew,
                      toggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      "Confirm Password",
                      _confirmPasswordController,
                      Icons.check_circle_outline_rounded,
                      obscure: _obscureConfirm,
                      toggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "SAVE CHANGES",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    return name
        .trim()
        .split(' ')
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'New Password' && v.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (label == 'Confirm Password' &&
            v != _newPasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _secondary),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.circle, size: 0),
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
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _muted.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }
}