import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/proximity_service.dart';
import '../models/staff.dart';

class LiveTrackingView extends StatefulWidget {
  final double guestLat;
  final double guestLong;
  final String incidentId;

  const LiveTrackingView({
    required this.guestLat,
    required this.guestLong,
    required this.incidentId,
  });

  @override
  _LiveTrackingViewState createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<LiveTrackingView> {
  final ProximityService _proximityService = ProximityService();
  double _distance = 0;
  StaffMember? _nearestStaff;
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _proximityService.startProximityTracking(
      guestLat: widget.guestLat,
      guestLong: widget.guestLong,
      incidentId: widget.incidentId,
      onUpdate: (distance, staff) {
        setState(() {
          _distance = distance;
          _nearestStaff = staff;
        });
      },
      onArrived: () {
        setState(() => _arrived = true);
      },
    );
  }

  @override
  void dispose() {
    _proximityService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng guestPos = LatLng(widget.guestLat, widget.guestLong);
    final LatLng? staffPos = _nearestStaff != null 
        ? LatLng(_nearestStaff!.location.latitude, _nearestStaff!.location.longitude) 
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("LIVE RESCUE TRACKER", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(center: guestPos, zoom: 16),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (staffPos != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [guestPos, staffPos],
                      color: Colors.blueAccent.withOpacity(0.5),
                      strokeWidth: 4,
                      isDotted: true,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // GUEST MARKER
                  Marker(
                    point: guestPos,
                    builder: (ctx) => const Icon(Icons.person_pin_circle, color: Colors.redAccent, size: 40),
                  ),
                  // STAFF MARKER
                  if (staffPos != null)
                    Marker(
                      point: staffPos,
                      builder: (ctx) => Column(
                        children: [
                          const Icon(Icons.directions_run, color: Colors.blueAccent, size: 35),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                            child: Text(_nearestStaff!.name, style: const TextStyle(color: Colors.white, fontSize: 8)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // DISTANCE HUD
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _arrived ? Colors.greenAccent : Colors.blueAccent.withOpacity(0.5), width: 2),
              ),
              child: Row(
                children: [
                  Icon(_arrived ? Icons.check_circle : Icons.radar, color: _arrived ? Colors.greenAccent : Colors.blueAccent, size: 30),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_arrived ? "STATUS: RESPONDER ON-SITE" : "RESPONDER EN ROUTE", 
                          style: TextStyle(color: _arrived ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_arrived ? "Contacting Sentinel Guardians..." : "Distance: ${_distance.toStringAsFixed(0)} meters",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      ],
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
}
