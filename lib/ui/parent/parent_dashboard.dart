import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/sos_alert_model.dart';
import '../../models/child_device_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_device_provider.dart';
import '../../services/firestore_service.dart';
import '../pairing/pairing_screen.dart';
import 'family_management_screen.dart';
import 'remote_controls_tab.dart';
import 'live_map_tab.dart';
import 'usage_stats_tab.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final familyId = authProvider.userModel?.familyId ?? 'fam_demo';
      final childProvider = Provider.of<ChildDeviceProvider>(context, listen: false);
      childProvider.listenToFamilyDevices(familyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildDeviceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final devices = childProvider.familyDevices;
    final activeDevice = devices.isNotEmpty ? devices.first : childProvider.childDevice;

    final List<Widget> tabs = [
      _buildFamilyLinkOverviewTab(activeDevice, devices),
      RemoteControlsTab(deviceId: activeDevice?.deviceId ?? 'device_demo'),
      LiveMapTab(device: activeDevice),
      const UsageStatsTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.googleBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.family_restroom_rounded, color: AppTheme.googleBlue, size: 26),
            const SizedBox(width: 8),
            Text(
              'DO you Family Link',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF202124),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, color: AppTheme.googleBlue),
            tooltip: 'Manage Family Devices',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyManagementScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppTheme.googleBlue),
            tooltip: 'Pair Device',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingScreen(isParent: true)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          tabs[_currentIndex],

          // Realtime SOS Emergency Alert Banner
          StreamBuilder<List<SOSAlertModel>>(
            stream: _firestoreService.streamSOSAlerts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }

              final alerts = snapshot.data!;
              final latestAlert = alerts.first;

              return Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.alertRed,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.alertRed,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('🚨', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EMERGENCY SOS ALERT!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${latestAlert.childName} pressed SOS! Location recorded.',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _firestoreService.resolveSOSAlert(latestAlert.alertId);
                          },
                          child: const Text(
                            'DISMISS',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.googleBlue,
          unselectedItemColor: const Color(0xFF70757A),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.phonelink_lock_outlined), label: 'Controls'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Location'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyLinkOverviewTab(ChildDeviceModel? device, List<ChildDeviceModel> realDevices) {
    final int usedMinutes = device?.usedMinutesToday ?? 45;
    final int limitMinutes = device?.dailyTimeLimitMinutes ?? 120;
    final double progress = (usedMinutes / limitMinutes).clamp(0.0, 1.0);
    final bool isLocked = device?.isLocked ?? false;
    final bool isOnline = device?.isOnline ?? true;
    final String devId = device?.deviceId ?? 'device_demo';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manage Family Devices Link Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Kids (${realDevices.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF202124),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyManagementScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Manage Kids'),
              )
            ],
          ),
          const SizedBox(height: 8),

          // 1. Real-time Device Status Card (Strictly Real Devices)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: isLocked ? AppTheme.alertRedLight : AppTheme.googleBlueLight,
                        child: Icon(
                          isLocked ? Icons.lock : Icons.smartphone,
                          size: 32,
                          color: isLocked ? AppTheme.alertRed : AppTheme.googleBlue,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isOnline ? AppTheme.accentGreen : const Color(0xFF9AA0A6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device?.childName ?? "Alex's Phone",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF202124),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.battery_charging_full, size: 16, color: AppTheme.accentGreen),
                            const SizedBox(width: 4),
                            Text(
                              '${device?.batteryLevel ?? 88}% Battery',
                              style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '• ${isOnline ? "Online" : "Offline"}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOnline ? AppTheme.accentGreen : const Color(0xFF70757A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Daily Quota Progress Bar Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Screen Time Today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF202124),
                        ),
                      ),
                      Text(
                        '${(usedMinutes / 60).toStringAsFixed(1)}h / ${(limitMinutes / 60).toStringAsFixed(1)}h',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.googleBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE8EAED),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? AppTheme.alertRed : AppTheme.googleBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. 6 NEW FUNCTIONAL CONTROL TOOLS GRID
          Text(
            '6 Remote Hardware Tools',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF202124),
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              // Tool 1: Wi-Fi Kill Switch
              _buildToolCard(
                icon: (device?.isWifiDisabled ?? false) ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                title: 'Wi-Fi Kill',
                subtitle: (device?.isWifiDisabled ?? false) ? 'Disabled' : 'Active',
                color: (device?.isWifiDisabled ?? false) ? AppTheme.alertRed : AppTheme.googleBlue,
                onTap: () {
                  final p = Provider.of<ChildDeviceProvider>(context, listen: false);
                  p.toggleWifiKill(devId, device?.isWifiDisabled ?? false);
                },
              ),
              // Tool 2: Remote Mute / Ringer Mode
              _buildToolCard(
                icon: (device?.isMuted ?? false) ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                title: 'Remote Mute',
                subtitle: (device?.isMuted ?? false) ? 'Silenced' : 'Normal',
                color: (device?.isMuted ?? false) ? AppTheme.alertRed : AppTheme.accentGreen,
                onTap: () {
                  final p = Provider.of<ChildDeviceProvider>(context, listen: false);
                  p.toggleRingerMute(devId, device?.isMuted ?? false);
                },
              ),
              // Tool 3: Remote Camera Lock
              _buildToolCard(
                icon: (device?.isCameraDisabled ?? false) ? Icons.no_photography_rounded : Icons.camera_alt_rounded,
                title: 'Camera Lock',
                subtitle: (device?.isCameraDisabled ?? false) ? 'Camera Disabled' : 'Allowed',
                color: (device?.isCameraDisabled ?? false) ? AppTheme.alertRed : AppTheme.warningAmber,
                onTap: () {
                  final p = Provider.of<ChildDeviceProvider>(context, listen: false);
                  p.toggleCameraLock(devId, device?.isCameraDisabled ?? false);
                },
              ),
              // Tool 4: Instant Siren Ring Alarm
              _buildToolCard(
                icon: (device?.isSirenActive ?? false) ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                title: 'Instant Siren Alarm',
                subtitle: (device?.isSirenActive ?? false) ? 'ALARM RINGING!' : 'Ring Phone',
                color: (device?.isSirenActive ?? false) ? AppTheme.alertRed : AppTheme.googleBlue,
                onTap: () {
                  final p = Provider.of<ChildDeviceProvider>(context, listen: false);
                  p.toggleSirenAlarm(devId, !(device?.isSirenActive ?? false));
                },
              ),
              // Tool 5: Bedtime Schedule Lock
              _buildToolCard(
                icon: Icons.bedtime_rounded,
                title: 'Bedtime Lock',
                subtitle: '${device?.bedtimeStart ?? "21:00"} - ${device?.bedtimeEnd ?? "07:00"}',
                color: AppTheme.googleBlue,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              // Tool 6: App Installation Blocker
              _buildToolCard(
                icon: (device?.isInstallBlocked ?? false) ? Icons.app_blocking_rounded : Icons.system_update_rounded,
                title: 'Install Blocker',
                subtitle: (device?.isInstallBlocked ?? false) ? 'Installs Blocked' : 'Allowed',
                color: (device?.isInstallBlocked ?? false) ? AppTheme.alertRed : AppTheme.accentGreen,
                onTap: () {
                  final p = Provider.of<ChildDeviceProvider>(context, listen: false);
                  p.toggleAppInstallBlock(devId, device?.isInstallBlocked ?? false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                radius: 20,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF202124),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF70757A), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
