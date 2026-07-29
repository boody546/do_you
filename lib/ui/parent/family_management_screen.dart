import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/child_device_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_device_provider.dart';
import '../pairing/pairing_screen.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final familyId = authProvider.userModel?.familyId ?? 'fam_demo';
      Provider.of<ChildDeviceProvider>(context, listen: false)
          .listenToFamilyDevices(familyId);
    });
  }

  void _showRenameDialog(BuildContext context, ChildDeviceModel device) {
    final controller = TextEditingController(text: device.childName);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Rename Child Device'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Device Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final p = Provider.of<ChildDeviceProvider>(context, listen: false);
                await p.renameChildDevice(device.deviceId, controller.text.trim());
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmUnpair(BuildContext context, ChildDeviceModel device) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final familyId = authProvider.userModel?.familyId ?? 'fam_demo';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Unpair Child Device?'),
        content: Text('Are you sure you want to unpair "${device.childName}"? Parental control shield will be disconnected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
            onPressed: () async {
              final p = Provider.of<ChildDeviceProvider>(context, listen: false);
              await p.unpairChildDevice(familyId, device.deviceId);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Unpair Device'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildDeviceProvider>(context);
    final devices = childProvider.familyDevices;

    return Scaffold(
      backgroundColor: AppTheme.googleBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Manage Family Devices',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF202124),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pair New Device Banner
              Card(
                color: AppTheme.googleBlueLight,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.googleBlue,
                        child: Icon(Icons.person_add, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Another Child Device',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF202124),
                              ),
                            ),
                            const Text(
                              'Generate a 6-digit PIN to pair another phone.',
                              style: TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PairingScreen(isParent: true)),
                          );
                        },
                        child: const Text('Pair'),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Linked Children Devices (${devices.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 12),

              if (devices.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.devices_other, size: 50, color: Color(0xFF9AA0A6)),
                          const SizedBox(height: 12),
                          Text(
                            'No Paired Children Devices Yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "Pair" above to generate a 6-digit invitation code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF5F6368), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final dev = devices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: dev.isLocked ? AppTheme.alertRedLight : AppTheme.googleBlueLight,
                          child: Icon(
                            dev.isLocked ? Icons.lock : Icons.smartphone,
                            color: dev.isLocked ? AppTheme.alertRed : AppTheme.googleBlue,
                          ),
                        ),
                        title: Text(
                          dev.childName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF202124),
                          ),
                        ),
                        subtitle: Text(
                          '${dev.deviceModel} • Battery: ${dev.batteryLevel}% • ${dev.isOnline ? "Online" : "Offline"}',
                          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'rename') {
                              _showRenameDialog(context, dev);
                            } else if (val == 'unpair') {
                              _confirmUnpair(context, dev);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rename', child: Text('Rename Device')),
                            PopupMenuItem(value: 'unpair', child: Text('Unpair Device', style: TextStyle(color: AppTheme.alertRed))),
                          ],
                        ),
                      ),
                    );
                  },
                )
            ],
          ),
        ),
      ),
    );
  }
}
