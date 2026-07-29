import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class LockOverlayScreen extends StatefulWidget {
  final String? message;
  const LockOverlayScreen({Key? key, this.message}) : super(key: key);

  @override
  State<LockOverlayScreen> createState() => _LockOverlayScreenState();
}

class _LockOverlayScreenState extends State<LockOverlayScreen> {
  bool _isSendingSOS = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _sendLockSOS() async {
    setState(() => _isSendingSOS = true);
    final pos = await LocationService.getCurrentPosition();

    await _firestoreService.sendSOSAlert(
      deviceId: 'device_child_demo',
      childName: 'Alex 🚀',
      latitude: pos?.latitude ?? 30.0444,
      longitude: pos?.longitude ?? 31.2357,
    );

    setState(() => _isSendingSOS = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency SOS Sent to Parents!'),
          backgroundColor: AppTheme.alertRose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Non-dismissible full-screen lock
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E1065), Color(0xFF0F172A), Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Playful Lock Emoji Icon
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF43F5E).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 6,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text('😴', style: TextStyle(fontSize: 54)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Time for a Break! 🌙',
                    style: GoogleFonts.fredoka(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    widget.message ??
                        'Great job today! Your daily phone limit has been reached or locked by your parent.\nTake a rest, play outside, or talk to your parents! ⭐️',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Emergency Call Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('📞', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 10),
                        Text(
                          'Emergency Call Available',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SOS Button on Lock Overlay
                  _isSendingSOS
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton.icon(
                          onPressed: _sendLockSOS,
                          icon: const Text('🆘', style: TextStyle(fontSize: 22)),
                          label: Text(
                            'SEND SOS TO PARENT',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
