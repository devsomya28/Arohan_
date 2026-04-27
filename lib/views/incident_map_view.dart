import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident.dart';
import '../viewmodels/staff_viewmodel.dart';
import 'dart:math';

class IncidentMapView extends StatefulWidget {
  @override
  _IncidentMapViewState createState() => _IncidentMapViewState();
}

class _IncidentMapViewState extends State<IncidentMapView> {
  Incident? _selectedIncident;

  Widget _buildSmartMap(List<Incident> incidents) {
    if (incidents.isEmpty) return Container(color: const Color(0xFF060E1A));
    
    final incident = incidents.first;
    const int zoom = 15;
    final n = pow(2, zoom);
    
    final int xTile = (n * ((incident.location.long + 180) / 360)).floor();
    final double latRad = incident.location.lat * pi / 180;
    final int yTile = (n * (1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2).floor();

    return Stack(
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemCount: 9,
          itemBuilder: (context, index) {
            final int dx = (index % 3) - 1;
            final int dy = (index ~/ 3) - 1;
            final url = 'https://tile.openstreetmap.org/$zoom/${xTile + dx}/${yTile + dy}.png';
            
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                -0.2126, -0.7152, -0.0722, 0, 255,
                -0.2126, -0.7152, -0.0722, 0, 255,
                -0.2126, -0.7152, -0.0722, 0, 255,
                0, 0, 0, 1, 0,
              ]),
              child: Image.network(url, fit: BoxFit.cover),
            );
          },
        ),
      ],
    );
  }

  Color _severityColor(int severity) {
    if (severity >= 8) return Colors.red;
    if (severity >= 5) return Colors.orange;
    return Colors.yellow;
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Icons.local_fire_department;
      case 'medical': return Icons.medical_services;
      case 'security': return Icons.security;
      default: return Icons.emergency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StaffViewModel>();
    final incidents = vm.activeIncidents;

    return Stack(
      children: [
        _buildSmartMap(incidents),
        // ── Incident detail popup ──
        if (_selectedIncident != null)
          Positioned(
            bottom: 20, left: 16, right: 16,
            child: _IncidentDetailCard(
              incident: _selectedIncident!,
              onClose: () => setState(() => _selectedIncident = null),
            ),
          ),

        // ── Header HUD ──
        Positioned(
          top: 16, left: 16, right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFF1E293B).withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(Icons.radar, color: Color(0xFF6366F1), size: 18),
                SizedBox(width: 10),
                const Text("LIVE INCIDENT MAP", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: incidents.isEmpty ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${incidents.length} ACTIVE",
                    style: TextStyle(
                      color: incidents.isEmpty ? Colors.green : Colors.redAccent,
                      fontSize: 10, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Empty state ──
        if (incidents.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, color: Colors.white12, size: 64),
                const SizedBox(height: 12),
                const Text("No incidents to map", style: TextStyle(color: Colors.white24, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }
}

class _IncidentDetailCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onClose;
  const _IncidentDetailCard({required this.incident, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = incident.severity >= 8 ? Colors.redAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: color, size: 16),
              const SizedBox(width: 8),
              Text("INCIDENT #${incident.id ?? '—'}", style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${incident.type.toUpperCase()} EMERGENCY",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Row(children: [
            _chip("Floor ${incident.location.floor}", Colors.white10, Colors.white54),
            const SizedBox(width: 8),
            _chip("Severity ${incident.severity}/10", color.withOpacity(0.2), color),
            const SizedBox(width: 8),
            _chip(incident.status.toUpperCase(), Colors.white10, Colors.white54),
          ]),
          if (incident.aiAnalysis != null) ...[
            const SizedBox(height: 10),
            Text(
              "AI: ${incident.aiAnalysis}",
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
