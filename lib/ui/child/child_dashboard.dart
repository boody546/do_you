import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/native/native_bridge.dart';
import '../../providers/child_device_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import 'lock_overlay_screen.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({Key? key}) : super(key: key);

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  bool _isAdminActive = false;
  bool _hasUsagePerm = false;
  bool _isSendingSOS = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkNativePermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<ChildDeviceProvider>(context, listen: false);
      p.listenToChildDevice('device_child_demo');
    });
  }

  Future<void> _checkNativePermissions() async {
    final admin = await NativeBridge.isAdminActive();
    final usage = await NativeBridge.hasUsagePermission();
    setState(() {
      _isAdminActive = admin;
      _hasUsagePerm = usage;
    });
  }

  Future<void> _triggerSOSAlert() async {
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
          content: Text('🚨 SOS Alert Sent to Parents Successfully!'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildDeviceProvider>(context);
    final device = childProvider.childDevice;
    final isLocked = childProvider.isLocked;
    final isSirenActive = device?.isSirenActive ?? false;

    // Realtime Siren Alarm Hardware Trigger
    if (isSirenActive) {
      NativeBridge.playSirenAlarm();
    } else {
      NativeBridge.stopSirenAlarm();
    }

    // Realtime Camera Lock Hardware Trigger
    if (device?.isCameraDisabled ?? false) {
      NativeBridge.setCameraDisabled(true);
    } else {
      NativeBridge.setCameraDisabled(false);
    }

    if (isLocked) {
      return const LockOverlayScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛡️ ', style: TextStyle(fontSize: 22)),
            Text(
              'DO you Kid Shield',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                if (isSirenActive) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.alertRed,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: const [
                        Text('🔊 🚨', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'SIREN ALARM RINGING! Parent is locating this phone.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Playful Mascot Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🚀', style: TextStyle(fontSize: 38)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You are Super Safe! 🌟',
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'DO you Shield is protecting your device in real-time.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Giant Emergency SOS Button Card
                Card(
                  color: const Color(0xFF881337),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Color(0xFFF43F5E), width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Need Help? 🚨',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Press the SOS button below to send your location instantly to your parents!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        _isSendingSOS
                            ? const CircularProgressIndicator(color: Colors.white)
                            : ElevatedButton.icon(
                                onPressed: _triggerSOSAlert,
                                icon: const Text('🆘', style: TextStyle(fontSize: 26)),
                                label: Text(
                                  'SEND EMERGENCY SOS',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE11D48),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 8,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Playful Screen Quota Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildPlayfulStatCard(
                        emoji: '⏳',
                        title: 'Time Used',
                        value: '${device?.usedMinutesToday ?? 45} Mins',
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildPlayfulStatCard(
                        emoji: '⚡️',
                        title: 'Battery',
                        value: '${device?.batteryLevel ?? 95}%',
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Protection Diagnostics Card
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFF334155)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shield Setup Check 🎮',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildKidPermRow(
                          'Device Admin Shield',
                          _isAdminActive,
                          onTap: () async {
                            await NativeBridge.requestAdminPermission();
                            _checkNativePermissions();
                          },
                        ),
                        const Divider(color: Color(0xFF334155)),
                        _buildKidPermRow(
                          'App Usage Monitor',
                          _hasUsagePerm,
                          onTap: () async {
                            await NativeBridge.requestUsagePermission();
                            _checkNativePermissions();
                          },
                        ),
                      ],
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

  Widget _buildPlayfulStatCard({
    required String emoji,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKidPermRow(String title, bool isGranted, {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(isGranted ? '✅' : '⚠️', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (!isGranted)
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Enable', style: TextStyle(fontSize: 12)),
          )
        else
          const Text(
            'Ready! ⭐',
            style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold),
          )
      ],
    );
  }
}
