import 'package:flutter/material.dart';
import 'package:lu_360/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  //get auth service
  final authService = AuthService();

  // 1. Controllers & Keys
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // For Sign Up

  // 2. UI State
  bool _isLogin = true; // Switch between Log In and Sign Up
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String _selectedRole = 'student'; // Default role
  final TextEditingController _adminCodeController = TextEditingController(); // Security check

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // 3. Authentication Logic
  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // SECURITY CHECK: If signing up as Admin, check a secret code
    if (!_isLogin && _selectedRole == 'admin') {
      if (_adminCodeController.text != "LU2026") { // Set your secret code here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Admin Code!")),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      if (_isLogin) {
        // Log In
        await authService.signInWithEmailPassword(email, password);
        debugPrint("Login successful for: $email");
      } else {
        // Sign Up
        if (password != confirmPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Passwords don't match")),
          );
          setState(() => _isLoading = false);
          return;
        } else{
          // 1. Sign Up the user
          await authService.signUpWithEmailPassword(email, password);

          // 2. Get the new user's ID
          final userId = Supabase.instance.client.auth.currentUser!.id;

          // 3. Save the name to the 'profiles' table
          await Supabase.instance.client.from('profiles').upsert({
            'id': userId,
            'full_name': _nameController.text.trim(),
          });

          debugPrint("Profile created for: ${_nameController.text}");
          debugPrint("Sign up successful for: $email");

          // Save 'role' to profiles
          await Supabase.instance.client.from('profiles').upsert({
            'id': userId,
            'full_name': _nameController.text.trim(),
            'role': _selectedRole, // <--- Saving the role
          });
        }
      }

      // ================= NAVIGATION ON SUCCESS =================
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
      // =========================================================

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication Failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.shield, size: 60, color: Color(0xFF1E88E5)),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 30),

                // Toggle Switch (Log In / Sign Up)
                _buildToggleSwitch(),
                const SizedBox(height: 30),

                // Name Field (Only visible during Sign Up)
                if (!_isLogin) ...[
                  const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Enter your full name'),
                    validator: (val) => val!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 20),
                ],

                // Email Field
                const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Enter your email'),
                  validator: (val) {
                    if (val == null || !val.contains('@')) return "Enter a valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration('Enter your password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (val) => val!.length < 6 ? "Password too short" : null,
                ),
                const SizedBox(height: 20),

                // Confirm Password Field (Only visible during Sign Up)
                if (!_isLogin) ...[
                  const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration('Confirm your password'),
                    validator: (val) => val!.isEmpty ? "Re-type your password" : null,
                  ),
                  const SizedBox(height: 20),
                ],

                // Forgot Password
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () { /* TODO: Forgot Password Navigation */ },
                      child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 20),

                if (!_isLogin) ...[
                  const Text('Select Role', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Student'),
                          value: 'student',
                          groupValue: _selectedRole,
                          onChanged: (val) => setState(() => _selectedRole = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Admin'),
                          value: 'admin',
                          groupValue: _selectedRole,
                          onChanged: (val) => setState(() => _selectedRole = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  // Admin Code Field (Only show if Admin is selected)
                  if (_selectedRole == 'admin') ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _adminCodeController,
                      decoration: _inputDecoration('Enter Admin Secret Code'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],

                // Action Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? 'Log In' : 'Sign Up', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 30),
                _buildDivider(),
                const SizedBox(height: 30),

                // Social Logins
                _buildSocialButton('Continue with Google', Icons.api, Colors.orange, () {
                  // TODO: Google Auth logic
                }),
                const SizedBox(height: 16),
                _buildSocialButton('Continue with University SSO', Icons.school, Colors.blue, () {
                  // TODO: SSO logic
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Toggle UI Component
  Widget _buildToggleSwitch() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // The animated white slider background
          AnimatedAlign(
            alignment: _isLogin ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.42,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
            ),
          ),
          // The interactive labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  // Makes the entire Expanded area hit-testable
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isLogin = true),
                  child: Center(
                    child: Text(
                        'Log In',
                        style: TextStyle(
                          fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                          color: _isLogin ? Colors.black : Colors.grey,
                        )
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isLogin = false),
                  child: Center(
                    child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                          color: !_isLogin ? Colors.black : Colors.grey,
                        )
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Input Decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSocialButton(String text, IconData icon, Color iconColor, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}