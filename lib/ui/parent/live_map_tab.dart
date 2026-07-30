import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/child_device_model.dart';
import '../../services/remote_command_service.dart';

class LiveMapTab extends StatefulWidget {
  final ChildDeviceModel? device;
  const LiveMapTab({Key? key, this.device}) : super(key: key);

  @override
  State<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends State<LiveMapTab> {
  GoogleMapController? _mapController;
  final RemoteCommandService _cmdService = RemoteCommandService();

  @override
  Widget build(BuildContext context) {
    final String deviceId = widget.device?.deviceId ?? 'device_demo';

    return Stack(
      children: [
        // ── Firebase RTDB Real-time Location Stream ─────────────────────────
        StreamBuilder<Map<String, dynamic>?>(
          stream: _cmdService.streamChildLocation(deviceId),
          builder: (context, rtdbSnap) {
            // Use RTDB location if available, fall back to Firestore device model
            double lat = widget.device?.latitude ?? 30.0444;
            double lng = widget.device?.longitude ?? 31.2357;
            double accuracy = 0;
            String lastUpdated = 'Syncing...';

            if (rtdbSnap.hasData && rtdbSnap.data != null) {
              final loc = rtdbSnap.data!;
              lat = (loc['latitude'] as num?)?.toDouble() ?? lat;
              lng = (loc['longitude'] as num?)?.toDouble() ?? lng;
              accuracy = (loc['accuracy'] as num?)?.toDouble() ?? 0;
              lastUpdated = 'Live — Just now';
            }

            final LatLng childPos = LatLng(lat, lng);

            return GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: childPos, zoom: 15),
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.animateCamera(
                    CameraUpdate.newLatLng(childPos));
              },
              myLocationEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('child_loc'),
                  position: childPos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
                  infoWindow: InfoWindow(
                    title: widget.device?.childName ?? "Child's Phone",
                    snippet:
                        'Battery: ${widget.device?.batteryLevel ?? 88}%  •  Accuracy: ${accuracy.toStringAsFixed(0)}m',
                  ),
                ),
              },
              circles: accuracy > 0
                  ? {
                      Circle(
                        circleId: const CircleId('accuracy_circle'),
                        center: childPos,
                        radius: accuracy,
                        fillColor: AppTheme.googleBlue.withOpacity(0.12),
                        strokeColor: AppTheme.googleBlue.withOpacity(0.4),
                        strokeWidth: 1,
                      ),
                    }
                  : {},
            );
          },
        ),

        // ── Floating Info Card ──────────────────────────────────────────────
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            color: Colors.white,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.my_location, color: AppTheme.accentGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live GPS Location',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF202124))),
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: _cmdService.streamChildLocation(deviceId),
                        builder: (ctx, snap) {
                          final loc = snap.data;
                          if (loc == null) {
                            return const Text('Waiting for GPS signal...',
                                style: TextStyle(
                                    color: Color(0xFF5F6368), fontSize: 12));
                          }
                          final lat = (loc['latitude'] as num).toStringAsFixed(5);
                          final lng = (loc['longitude'] as num).toStringAsFixed(5);
                          return Text('$lat, $lng',
                              style: const TextStyle(
                                  color: Color(0xFF5F6368), fontSize: 12));
                        },
                      ),
                    ],
                  ),
                ),
                Column(children: [
                  // Recenter button
                  IconButton(
                    icon: const Icon(Icons.center_focus_strong,
                        color: AppTheme.googleBlue),
                    onPressed: () async {
                      final loc = await _cmdService
                          .streamChildLocation(deviceId)
                          .first;
                      if (loc != null && _mapController != null) {
                        final lat =
                            (loc['latitude'] as num).toDouble();
                        final lng =
                            (loc['longitude'] as num).toDouble();
                        _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
                      }
                    },
                  ),
                  // Ping GPS button
                  GestureDetector(
                    onTap: () async {
                      await _cmdService.requestLocation(deviceId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('📍 Location ping sent!'),
                            backgroundColor: AppTheme.accentGreen),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.googleBlueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PING',
                          style: TextStyle(
                              color: AppTheme.googleBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
