import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/native/native_bridge.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
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

  // Mandatory Pre-Pairing Permission Checklist States
  bool _isAdminGranted = false;
  bool _isLocationGranted = false;
  bool _isUsageGranted = false;
  bool _isOverlayGranted = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isParent) {
      _checkPermissionsStatus();
    }
  }

  Future<void> _checkPermissionsStatus() async {
    final admin = await NativeBridge.isAdminActive();
    final usage = await NativeBridge.hasUsagePermission();
    final pos = await LocationService.getCurrentPosition();

    setState(() {
      _isAdminGranted = admin;
      _isUsageGranted = usage;
      _isLocationGranted = pos != null;
      _isOverlayGranted = true; // Placeholder for system alert window
    });
  }

  bool get _areAllPermissionsGranted =>
      _isAdminGranted && _isUsageGranted && _isLocationGranted;

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.googleBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.isParent ? 'Pair New Device' : 'Connect to Parent',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF202124),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: widget.isParent
              ? _buildParentPairingView(familyProvider, authProvider)
              : _buildChildPairingView(familyProvider),
        ),
      ),
    );
  }

  Widget _buildParentPairingView(FamilyProvider familyProvider, AuthProvider authProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.googleBlueLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 70, color: AppTheme.googleBlue),
        ),
        const SizedBox(height: 24),
        Text(
          '6-Digit Invitation Code',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter this 6-digit code on your child\'s phone to complete pairing.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 14),
        ),
        const SizedBox(height: 32),

        if (familyProvider.pairingCode != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
            decoration: BoxDecoration(
              gradient: AppTheme.familyLinkGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.googleBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Text(
              familyProvider.pairingCode!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 42,
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
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Generate 6-Digit Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.googleBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
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
            side: const BorderSide(color: AppTheme.googleBlue),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Go to Parent Dashboard', style: TextStyle(color: AppTheme.googleBlue, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildChildPairingView(FamilyProvider familyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(Icons.phonelink_setup_rounded, size: 64, color: AppTheme.googleBlue),
        ),
        const SizedBox(height: 16),
        Text(
          'Connect Child Device',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Input device name & the 6-digit PIN code displayed on your parent\'s DO you app',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13),
        ),
        const SizedBox(height: 24),

        // 1. Inputs Section with Fixed Dark Text Color (#202124)
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Information',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 12),

                // Child Device Name Input (FIXED: Dark #202124 Text Color)
                TextField(
                  controller: _childNameController,
                  style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Child Device Name',
                    labelStyle: const TextStyle(color: Color(0xFF5F6368)),
                    prefixIcon: const Icon(Icons.person, color: AppTheme.googleBlue),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 6-Digit PIN Code Input (FIXED: Dark #202124 Text Color)
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF202124),
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: const TextStyle(color: Color(0xFF9AA0A6), letterSpacing: 8),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Mandatory Pre-Pairing Android Permission Checklist Card
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mandatory Permissions Flow',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF202124),
                      ),
                    ),
                    Icon(
                      _areAllPermissionsGranted ? Icons.check_circle : Icons.error_outline,
                      color: _areAllPermissionsGranted ? AppTheme.accentGreen : AppTheme.warningAmber,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Grant required permissions before pairing to ensure remote lock & GPS tracking work seamlessly.',
                  style: TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                ),
                const SizedBox(height: 16),

                _buildPermissionCheckTile(
                  title: '1. Device Administrator Rights',
                  subtitle: 'Allows hardware remote screen lock',
                  isGranted: _isAdminGranted,
                  onTap: () async {
                    await NativeBridge.requestAdminPermission();
                    _checkPermissionsStatus();
                  },
                ),
                const Divider(color: Color(0xFFE0E0E0)),

                _buildPermissionCheckTile(
                  title: '2. GPS Location Access',
                  subtitle: 'Enables live map safety tracking',
                  isGranted: _isLocationGranted,
                  onTap: () async {
                    await LocationService.getCurrentPosition();
                    _checkPermissionsStatus();
                  },
                ),
                const Divider(color: Color(0xFFE0E0E0)),

                _buildPermissionCheckTile(
                  title: '3. App Usage Access',
                  subtitle: 'Monitors daily screen time quotas',
                  isGranted: _isUsageGranted,
                  onTap: () async {
                    await NativeBridge.requestUsagePermission();
                    _checkPermissionsStatus();
                  },
                ),
                const Divider(color: Color(0xFFE0E0E0)),

                _buildPermissionCheckTile(
                  title: '4. System Alert Overlay',
                  subtitle: 'Displays fullscreen lock screen',
                  isGranted: _isOverlayGranted,
                  onTap: () => _checkPermissionsStatus(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Pair Device Button with Exception Handling Banners
        if (familyProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _areAllPermissionsGranted ? AppTheme.googleBlue : const Color(0xFF9AA0A6),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _areAllPermissionsGranted
                ? () async {
                    if (_codeController.text.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter full 6-digit PIN code')),
                      );
                      return;
                    }

                    try {
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
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pairing Error: Unable to verify 6-digit code. Please check internet connection or pairing PIN.'),
                            backgroundColor: AppTheme.alertRed,
                          ),
                        );
                      }
                    }
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please grant all mandatory Android permissions before pairing.'),
                        backgroundColor: AppTheme.warningAmber,
                      ),
                    );
                  },
            child: Text(
              _areAllPermissionsGranted ? 'Pair Device Now' : 'Grant All Permissions First',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

        if (familyProvider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.alertRedLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Pairing Notice: ${familyProvider.error!}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildPermissionCheckTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF202124),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF70757A), fontSize: 12),
              ),
            ],
          ),
        ),
        if (!isGranted)
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.googleBlue),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Grant', style: TextStyle(color: AppTheme.googleBlue, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        else
          Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 20),
              SizedBox(width: 4),
              Text('Granted', style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          )
      ],
    );
  }
}
