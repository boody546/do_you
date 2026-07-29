import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/child_device_provider.dart';

class RemoteControlsTab extends StatefulWidget {
  final String deviceId;
  const RemoteControlsTab({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<RemoteControlsTab> createState() => _RemoteControlsTabState();
}

class _RemoteControlsTabState extends State<RemoteControlsTab> {
  double _dailyLimitHours = 2.0;

  final List<Map<String, String>> _sampleApps = [
    {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'category': 'Social Media'},
    {'name': 'YouTube', 'package': 'com.google.android.youtube', 'category': 'Entertainment'},
    {'name': 'Roblox', 'package': 'com.roblox.client', 'category': 'Games'},
    {'name': 'Instagram', 'package': 'com.instagram.android', 'category': 'Social Media'},
    {'name': 'Chrome Browser', 'package': 'com.android.chrome', 'category': 'Productivity'},
  ];

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildDeviceProvider>(context);
    final device = childProvider.childDevice;
    final bool isLocked = device?.isLocked ?? false;
    final List<String> blockedApps = device?.blockedAppPackages ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instant Remote Lock Control Card
          Card(
            color: isLocked ? AppTheme.alertRedLight : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Immediate Remote Lock',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocked ? 'Child screen is currently LOCKED' : 'Child screen is UNLOCKED',
                        style: TextStyle(
                          color: isLocked ? AppTheme.alertRed : const Color(0xFF5F6368),
                          fontSize: 13,
                          fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isLocked,
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.alertRed,
                    onChanged: (val) {
                      childProvider.toggleRemoteLock(widget.deviceId, val);
                    },
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Daily Screen Time Limit Card
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
                        'Daily Screen Time Limit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF202124),
                        ),
                      ),
                      Text(
                        '${_dailyLimitHours.toStringAsFixed(1)} Hours',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.googleBlue,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _dailyLimitHours,
                    min: 0.5,
                    max: 8.0,
                    divisions: 15,
                    activeColor: AppTheme.googleBlue,
                    inactiveColor: const Color(0xFFE8EAED),
                    onChanged: (val) {
                      setState(() => _dailyLimitHours = val);
                    },
                    onChangeEnd: (val) {
                      childProvider.setDailyLimit(widget.deviceId, (val * 60).round());
                    },
                  ),
                  const Text(
                    'Automatically locks child screen when limit expires.',
                    style: TextStyle(color: Color(0xFF70757A), fontSize: 12),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Per-App Blocking List
          Text(
            'App Block Restrictions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF202124),
            ),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sampleApps.length,
            itemBuilder: (context, index) {
              final app = _sampleApps[index];
              final String pkg = app['package']!;
              final bool isBlocked = blockedApps.contains(pkg);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBlocked ? AppTheme.alertRedLight : AppTheme.googleBlueLight,
                    child: Icon(
                      isBlocked ? Icons.block : Icons.apps,
                      color: isBlocked ? AppTheme.alertRed : AppTheme.googleBlue,
                    ),
                  ),
                  title: Text(
                    app['name']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  subtitle: Text(app['category']!, style: const TextStyle(color: Color(0xFF70757A))),
                  trailing: Switch(
                    value: isBlocked,
                    activeColor: AppTheme.alertRed,
                    onChanged: (val) {
                      childProvider.toggleAppBlock(widget.deviceId, pkg, isBlocked);
                    },
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
