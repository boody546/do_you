import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../child/child_dashboard.dart';
import '../parent/parent_dashboard.dart';

class PairingScreen extends StatefulWidget {
  final bool isParent;
  const PairingScreen({Key? key, required this.isParent}) : super(key: key);

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _childNameController = TextEditingController(text: 'Child Device');

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isParent ? 'Pair New Device' : 'Connect to Parent'),
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: widget.isParent
            ? _buildParentPairingView(familyProvider, authProvider)
            : _buildChildPairingView(familyProvider),
      ),
    );
  }

  Widget _buildParentPairingView(FamilyProvider familyProvider, AuthProvider authProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_scanner, size: 80, color: AppTheme.primaryCyan),
        const SizedBox(height: 24),
        Text(
          '6-Digit Pairing Invitation Code',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter this 6-digit code on your child\'s phone to complete pairing.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 32),

        if (familyProvider.pairingCode != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                )
              ],
            ),
            child: Text(
              familyProvider.pairingCode!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
                color: Colors.white,
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () {
              final uid = authProvider.userModel?.uid ?? 'parent_123';
              familyProvider.generateInviteCode(uid);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Generate 6-Digit Code'),
          ),

        const SizedBox(height: 48),
        OutlinedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ParentDashboard()),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryCyan),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Go to Parent Dashboard', style: TextStyle(color: AppTheme.primaryCyan)),
        )
      ],
    );
  }

  Widget _buildChildPairingView(FamilyProvider familyProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.phonelink_setup, size: 70, color: AppTheme.accentEmerald),
        const SizedBox(height: 20),
        Text(
          'Enter Pairing Code',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Input the 6-digit code displayed on your parent\'s DO you app',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 32),

        TextField(
          controller: _childNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Child/Device Name',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.person, color: AppTheme.accentEmerald),
            filled: true,
            fillColor: AppTheme.darkCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentEmerald,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
            filled: true,
            fillColor: AppTheme.darkCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 24),

        if (familyProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentEmerald,
            ),
            onPressed: () async {
              if (_codeController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter full 6-digit code')),
                );
                return;
              }

              final success = await familyProvider.pairChildWithCode(
                code: _codeController.text,
                childDeviceName: _childNameController.text,
                deviceId: 'device_android_${DateTime.now().millisecondsSinceEpoch}',
              );

              if (success && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ChildDashboard()),
                );
              }
            },
            child: const Text('Pair Device Now'),
          ),

        if (familyProvider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              familyProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.alertRose),
            ),
          )
      ],
    );
  }
}
