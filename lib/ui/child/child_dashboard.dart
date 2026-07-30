import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/native/native_bridge.dart';
import '../../providers/child_device_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/remote_command_service.dart';
import '../../services/preference_service.dart';
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
  bool _locationStreaming = false;

  final FirestoreService _firestoreService = FirestoreService();
  final LocationStreamService _locationStream = LocationStreamService();

  String _deviceId = 'device_child_demo';

  @override
  void initState() {
    super.initState();
    _initChildDevice();
  }

  Future<void> _initChildDevice() async {
    // Load persisted deviceId from SharedPreferences
    final session = await PreferenceService.getSession();
    final savedId = session['deviceId'] ?? 'device_child_demo';
    setState(() => _deviceId = savedId);

    // Listen to Firestore child device state
    final p = Provider.of<ChildDeviceProvider>(context, listen: false);
    p.listenToChildDevice(_deviceId);

    // Start native Kotlin Firebase command listener service
    await NativeBridge.startCommandListener(_deviceId);

    // Start GPS location streaming to Firebase RTDB
    await _locationStream.startStreaming(_deviceId);
    setState(() => _locationStreaming = true);

    // Check native permissions
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final admin = await NativeBridge.isAdminActive();
    final usage = await NativeBridge.hasUsagePermission();
    if (mounted) {
      setState(() {
        _isAdminActive = admin;
        _hasUsagePerm = usage;
      });
    }
  }

  Future<void> _triggerSOSAlert() async {
    setState(() => _isSendingSOS = true);
    try {
      await _firestoreService.sendSOSAlert(
        deviceId: _deviceId,
        childName: 'Alex 🚀',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 SOS Alert Sent to Parents Successfully!'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingSOS = false);
    }
  }

  @override
  void dispose() {
    _locationStream.stopStreaming();
    NativeBridge.stopCommandListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildDeviceProvider>(context);
    final device = childProvider.childDevice;
    final bool isLocked = childProvider.isLocked;
    final bool isSirenActive = device?.isSirenActive ?? false;
    final bool isCameraDisabled = device?.isCameraDisabled ?? false;

    // Hardware triggers based on Firestore state
    if (isSirenActive) NativeBridge.playSirenAlarm();
    if (!isSirenActive) NativeBridge.stopSirenAlarm();
    if (isCameraDisabled) NativeBridge.setCameraDisabled(true);
    if (!isCameraDisabled) NativeBridge.setCameraDisabled(false);

    if (isLocked) return const LockOverlayScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Icon(
                  _locationStreaming ? Icons.gps_fixed : Icons.gps_off,
                  color: _locationStreaming
                      ? AppTheme.accentGreen
                      : const Color(0xFF9AA0A6),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _locationStreaming ? 'GPS Live' : 'GPS Off',
                  style: TextStyle(
                    color: _locationStreaming
                        ? AppTheme.accentGreen
                        : const Color(0xFF9AA0A6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Siren Active Banner
                if (isSirenActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.alertRed,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Text('🔊 🚨', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'SIREN ALARM RINGING!\nParent is locating this phone.',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      ),
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
                            Text(
                              'DO you Shield is protecting your device in real-time.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Giant SOS Button
                Card(
                  color: const Color(0xFF881337),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Color(0xFFF43F5E), width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : ElevatedButton.icon(
                                onPressed: _triggerSOSAlert,
                                icon: const Text('🆘',
                                    style: TextStyle(fontSize: 26)),
                                label: Text(
                                  'SEND EMERGENCY SOS',
                                  style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE11D48),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
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

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        emoji: '⏳',
                        title: 'Time Used',
                        value: '${device?.usedMinutesToday ?? 0} Mins',
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatCard(
                        emoji: '⚡️',
                        title: 'Battery',
                        value: '${device?.batteryLevel ?? 95}%',
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Shield diagnostics card
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFF334155)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                        _buildPermRow(
                          'Device Admin Shield',
                          _isAdminActive,
                          onTap: () async {
                            await NativeBridge.requestAdminPermission();
                            _checkPermissions();
                          },
                        ),
                        const Divider(color: Color(0xFF334155)),
                        _buildPermRow(
                          'App Usage Monitor',
                          _hasUsagePerm,
                          onTap: () async {
                            await NativeBridge.requestUsagePermission();
                            _checkPermissions();
                          },
                        ),
                        const Divider(color: Color(0xFF334155)),
                        _buildPermRow(
                          'Live GPS Tracking',
                          _locationStreaming,
                          onTap: () async {
                            await _locationStream.startStreaming(_deviceId);
                            setState(() => _locationStreaming = true);
                          },
                        ),
                        const Divider(color: Color(0xFF334155)),
                        _buildPermRow(
                          'Firebase Shield Listener',
                          true, // always true once initChildDevice runs
                          onTap: () {},
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

  Widget _buildStatCard({
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
          Text(title,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: GoogleFonts.fredoka(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildPermRow(String title, bool granted,
      {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Text(granted ? '✅' : '⚠️', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        if (!granted)
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Enable', style: TextStyle(fontSize: 12)),
          )
        else
          const Text('Ready! ⭐',
              style: TextStyle(
                  color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
