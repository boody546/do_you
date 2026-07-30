import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/native/native_bridge.dart';
import '../../providers/child_device_provider.dart';
import '../../services/remote_command_service.dart';

class AntiTheftControlsTab extends StatefulWidget {
  final String deviceId;
  const AntiTheftControlsTab({Key? key, required this.deviceId})
      : super(key: key);

  @override
  State<AntiTheftControlsTab> createState() => _AntiTheftControlsTabState();
}

class _AntiTheftControlsTabState extends State<AntiTheftControlsTab> {
  bool _isAdminActive = false;
  bool _hasDNDPerm = false;
  bool _isAccessibilityEnabled = false;
  bool _sirenPlaying = false;
  bool _sendingCommand = false;

  final RemoteCommandService _cmdService = RemoteCommandService();

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final admin = await NativeBridge.isAdminActive();
    final dnd = await NativeBridge.hasDNDPermission();
    final acc = await NativeBridge.isAccessibilityEnabled();
    if (mounted) {
      setState(() {
        _isAdminActive = admin;
        _hasDNDPerm = dnd;
        _isAccessibilityEnabled = acc;
      });
    }
  }

  Future<void> _sendRTDBCommand(Future<void> Function() action) async {
    setState(() => _sendingCommand = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Command sent to child device via Firebase!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Command failed: ${e.toString()}'),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingCommand = false);
    }
  }

  void _confirmFactoryReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(children: [
          Text('⚠️ ', style: TextStyle(fontSize: 22)),
          Text('FACTORY RESET WARNING'),
        ]),
        content: const Text(
          'This will PERMANENTLY DELETE all data on the child device.\n\n'
          'Only use this if the device is stolen. This action CANNOT be undone!',
          style: TextStyle(color: Color(0xFF3C4043)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.alertRed),
            onPressed: () {
              Navigator.pop(ctx);
              _sendRTDBCommand(
                  () => _cmdService.wipeDevice(widget.deviceId));
            },
            child: const Text('WIPE ALL DATA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildDeviceProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Permissions Status Card ─────────────────────────────────────
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Required Permissions',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF202124))),
                  const SizedBox(height: 12),
                  _buildPermRow(
                    title: 'Device Admin (Lock & Wipe)',
                    isGranted: _isAdminActive,
                    onTap: () async {
                      await NativeBridge.requestAdminPermission();
                      _refreshStatus();
                    },
                  ),
                  const Divider(),
                  _buildPermRow(
                    title: 'Do Not Disturb Override',
                    isGranted: _hasDNDPerm,
                    onTap: () async {
                      await NativeBridge.requestDNDPermission();
                      _refreshStatus();
                    },
                  ),
                  const Divider(),
                  _buildPermRow(
                    title: 'Accessibility (Browser Monitor)',
                    isGranted: _isAccessibilityEnabled,
                    onTap: () async {
                      await NativeBridge.requestAccessibilityPermission();
                      _refreshStatus();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Anti-Theft Remote Commands',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF202124))),
          const SizedBox(height: 4),
          const Text(
            'Commands are sent via Firebase Realtime Database and executed instantly on the child device.',
            style: TextStyle(color: Color(0xFF5F6368), fontSize: 12),
          ),
          const SizedBox(height: 14),

          if (_sendingCommand)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            ),

          // ── Siren Alarm Card ────────────────────────────────────────────
          Card(
            color: _sirenPlaying ? AppTheme.alertRedLight : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🚨', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Anti-Theft Siren Alarm',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: const Color(0xFF202124))),
                          const Text(
                              'Rings at MAX volume even in Silent / DND mode.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF5F6368))),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _sirenPlaying
                              ? const Color(0xFF555555)
                              : AppTheme.alertRed,
                        ),
                        onPressed: _sendingCommand
                            ? null
                            : () async {
                                if (_sirenPlaying) {
                                  await _sendRTDBCommand(() =>
                                      _cmdService.stopAlarm(widget.deviceId));
                                  setState(() => _sirenPlaying = false);
                                } else {
                                  await _sendRTDBCommand(() =>
                                      _cmdService.triggerAlarm(widget.deviceId));
                                  setState(() => _sirenPlaying = true);
                                }
                              },
                        icon: Icon(_sirenPlaying ? Icons.stop : Icons.volume_up),
                        label: Text(
                            _sirenPlaying ? 'STOP ALARM' : 'RING DEVICE NOW'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Remote Lock Card ────────────────────────────────────────────
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const Text('🔒', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remote Screen Lock',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF202124))),
                      const Text('Instantly locks the child device screen via Firebase.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF5F6368))),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.googleBlue),
                  onPressed: _sendingCommand
                      ? null
                      : () => _sendRTDBCommand(
                          () => _cmdService.lockScreen(widget.deviceId)),
                  child: const Text('LOCK NOW'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── Request Location Card ───────────────────────────────────────
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const Text('📍', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ping Live Location',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF202124))),
                      const Text('Forces the child device to push GPS location now.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF5F6368))),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen),
                  onPressed: _sendingCommand
                      ? null
                      : () => _sendRTDBCommand(
                          () => _cmdService.requestLocation(widget.deviceId)),
                  child: const Text('PING GPS'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── Factory Reset Card ──────────────────────────────────────────
          Card(
            color: AppTheme.alertRedLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.alertRed, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('💀', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Factory Reset — Anti-Theft Wipe',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.alertRed)),
                          const Text(
                              'Permanently wipes ALL data if device is stolen.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF5F6368))),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.alertRed,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed:
                          _sendingCommand ? null : _confirmFactoryReset,
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: const Text('WIPE DEVICE — FACTORY RESET',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Browser Activity Monitor ────────────────────────────────────
          Text('Child Browser Activity',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF202124))),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live URL Capture (Accessibility Service)',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF202124))),
                  const SizedBox(height: 6),
                  const Text(
                      'Monitors URLs visited in Chrome, Firefox, Edge, and Opera.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                  const SizedBox(height: 14),
                  FutureBuilder<String>(
                    future: NativeBridge.getLastBrowserUrl(),
                    builder: (ctx, snap) {
                      final url = snap.data ?? '';
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          url.isEmpty
                              ? '🔍 No browser activity captured yet.\nEnable Accessibility Service to start monitoring.'
                              : '🌐 $url',
                          style: const TextStyle(
                            color: Color(0xFF202124),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (!_isAccessibilityEnabled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.googleBlue),
                        onPressed: () async {
                          await NativeBridge.requestAccessibilityPermission();
                          _refreshStatus();
                        },
                        icon: const Icon(Icons.accessibility_new),
                        label: const Text('Enable Accessibility Service'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermRow({
    required String title,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Text(isGranted ? '✅' : '⚠️', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF202124),
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
        if (!isGranted)
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.googleBlue),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Grant',
                style: TextStyle(
                    color: AppTheme.googleBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          )
        else
          const Text('Active',
              style: TextStyle(
                  color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
