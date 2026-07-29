import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/child_device_model.dart';

class LiveMapTab extends StatefulWidget {
  final ChildDeviceModel? device;
  const LiveMapTab({Key? key, this.device}) : super(key: key);

  @override
  State<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends State<LiveMapTab> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final double lat = widget.device?.latitude ?? 30.0444;
    final double lng = widget.device?.longitude ?? 31.2357;
    final LatLng childPos = LatLng(lat, lng);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: childPos, zoom: 15),
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            Marker(
              markerId: const MarkerId('child_loc'),
              position: childPos,
              infoWindow: InfoWindow(
                title: widget.device?.childName ?? "Child's Phone",
                snippet: 'Battery: ${widget.device?.batteryLevel ?? 88}%',
              ),
            )
          },
        ),

        // Floating Info Card Header
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            color: Colors.white,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentGreenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location, color: AppTheme.accentGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live GPS Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF202124),
                          ),
                        ),
                        Text(
                          'GPS Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.center_focus_strong, color: AppTheme.googleBlue),
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(childPos, 16),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
