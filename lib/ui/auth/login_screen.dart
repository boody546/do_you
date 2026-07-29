import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../parent/parent_dashboard.dart';
import '../pairing/pairing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  String _selectedRole = AppConstants.roleParent;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.googleBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Family Link Style Brand Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.googleBlueLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.googleBlue.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    size: 46,
                    color: AppTheme.googleBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF202124),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Family Link Shield & Device Manager',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(height: 32),

                // Role Tab Switcher Card
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = AppConstants.roleParent),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == AppConstants.roleParent
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedRole == AppConstants.roleParent
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Parent Device',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == AppConstants.roleParent
                                      ? AppTheme.googleBlue
                                      : const Color(0xFF5F6368),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = AppConstants.roleChild),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == AppConstants.roleChild
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _selectedRole == AppConstants.roleChild
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Child Device',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == AppConstants.roleChild
                                      ? AppTheme.googleBlue
                                      : const Color(0xFF5F6368),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _selectedRole == AppConstants.roleChild
                                ? 'Child Device Setup'
                                : (_isLoginMode ? 'Parent Sign In' : 'Create Parent Account'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_selectedRole == AppConstants.roleChild) ...[
                            Text(
                              'Connect this device to your parent\'s DO you Family Link account using a 6-digit PIN code.',
                              style: const TextStyle(color: Color(0xFF5F6368), fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PairingScreen(isParent: false),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Enter 6-Digit PIN Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.googleBlue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ] else ...[
                            // Google One-Tap Style Sign In Button
                            OutlinedButton.icon(
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Google Sign-In Initiated...')),
                                );
                              },
                              icon: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                                height: 22,
                                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: AppTheme.googleBlue, size: 28),
                              ),
                              label: Text(
                                'Sign in with Google',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3C4043),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFDADCE0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: const [
                                Expanded(child: Divider(color: Color(0xFFDADCE0))),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('OR', style: TextStyle(color: Color(0xFF70757A), fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: Color(0xFFDADCE0))),
                              ],
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Color(0xFF202124)),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.googleBlue),
                                filled: true,
                                fillColor: const Color(0xFFF1F3F4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Color(0xFF202124)),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.googleBlue),
                                filled: true,
                                fillColor: const Color(0xFFF1F3F4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                            ),
                            const SizedBox(height: 24),

                            if (authProvider.status == AuthStatus.loading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton(
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) return;

                                  bool success;
                                  if (_isLoginMode) {
                                    success = await authProvider.login(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                  } else {
                                    success = await authProvider.registerParent(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                  }

                                  if (success && mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ParentDashboard(),
                                      ),
                                    );
                                  }
                                },
                                child: Text(_isLoginMode ? 'Sign In' : 'Create Account'),
                              ),
                            const SizedBox(height: 12),

                            TextButton(
                              onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                              child: Text(
                                _isLoginMode
                                    ? "Don't have an account? Register"
                                    : "Already registered? Sign In",
                                style: const TextStyle(color: AppTheme.googleBlue),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
