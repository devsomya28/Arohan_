import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident.dart';
import '../viewmodels/staff_viewmodel.dart';
import '../models/staff.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class CommanderMapView extends StatefulWidget {
  @override
  _CommanderMapViewState createState() => _CommanderMapViewState();
}

class _CommanderMapViewState extends State<CommanderMapView> with SingleTickerProviderStateMixin {
  Incident? _selectedIncident;
  MapType _mapType = MapType.normal;

  Widget _buildSmartMap(List<Incident> incidents, List<StaffMember> staffList) {
    if (incidents.isEmpty) return Container(color: const Color(0xFF060E1A));
    
    final incident = incidents.first;
    const int zoom = 15;
    final n = pow(2, zoom);
    
    final int xTile = (n * ((incident.location.long + 180) / 360)).floor();
    final double latRad = incident.location.lat * pi / 180;
    final int yTile = (n * (1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2).floor();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200 ? 5 : (constraints.maxWidth > 800 ? 4 : 3);
        int totalTiles = crossAxisCount * crossAxisCount;

        return Stack(
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount),
              itemCount: totalTiles,
              itemBuilder: (context, index) {
                final int dx = (index % crossAxisCount) - (crossAxisCount ~/ 2);
                final int dy = (index ~/ crossAxisCount) - (crossAxisCount ~/ 2);
                final url = 'https://tile.openstreetmap.org/$zoom/${xTile + dx}/${yTile + dy}.png';
                
                return Image.network(
                  url, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                );
              },
            ),
            
            // Incident Marker (The Person in Need)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                    child: const Text("VICTIM", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                ],
              ),
            ),

            // Staff Markers (The Responders)
            ...staffList.map((staff) {
              return Positioned(
                left: (constraints.maxWidth / 2) + (staff.location.longitude - incident.location.long) * 10000,
                top: (constraints.maxHeight / 2) - (staff.location.latitude - incident.location.lat) * 10000,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_run, color: Colors.blueAccent, size: 30),
                    Text(staff.name, style: const TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StaffViewModel>();
    final incidents = vm.activeIncidents;

    final int fireCount = incidents.where((i) => i.type.toLowerCase() == 'fire').length;
    final int medCount = incidents.where((i) => i.type.toLowerCase() == 'medical').length;
    final int sosCount = incidents.where((i) => !['fire','medical'].contains(i.type.toLowerCase())).length;

    return Stack(
      children: [
        _buildSmartMap(incidents, vm.activeStaff),

        // ── TOP HUD ──
        Positioned(
          top: 16, left: 16, right: 16,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E36).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _hudStat("${sosCount}", "SOS", Colors.indigoAccent),
                    _vDivider(),
                    _hudStat("${fireCount}", "FIRE", Colors.redAccent),
                    _vDivider(),
                    _hudStat("${medCount}", "MEDICAL", Colors.greenAccent),
                    _vDivider(),
                    _hudStat("${incidents.length}", "TOTAL", Colors.white54),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── SELECTED incident detail ──
        if (_selectedIncident != null)
          Positioned(
            bottom: 20, left: 16, right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _DetailPopup(
                  incident: _selectedIncident!,
                  staffList: vm.activeStaff,
                  onClose: () => setState(() => _selectedIncident = null),
                ),
              ),
            ),
          ),

        // ── Map controls ──
        Positioned(
          top: 90, right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _mapToggleBtn(Icons.map, "ROAD", MapType.grid),
                _mapToggleBtn(Icons.satellite_alt, "SAT", MapType.satellite),
              ],
            ),
          ),
        ),

        // ── Empty state ──
        if (incidents.isEmpty)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.crisis_alert, color: Colors.white12, size: 72),
                SizedBox(height: 12),
                Text("All Clear — No Active Incidents", style: TextStyle(color: Colors.white24, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _hudStat(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 32, color: Colors.white10);

  Widget _mapToggleBtn(IconData icon, String label, MapType type) {
    final bool active = (type == MapType.grid && _mapType == MapType.normal) || (type == MapType.satellite && _mapType == MapType.satellite);
    return GestureDetector(
      onTap: () => setState(() => _mapType = (type == MapType.grid ? MapType.normal : MapType.satellite)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: active ? const Color(0xFF6366F1) : Colors.white24, size: 20),
      ),
    );
  }
}

enum MapType { grid, satellite, normal }

class _DetailPopup extends StatelessWidget {
  final Incident incident;
  final List<StaffMember> staffList;
  final VoidCallback onClose;
  const _DetailPopup({required this.incident, required this.staffList, required this.onClose});

  @override
  Widget build(BuildContext context) {
    double minDistance = -1;
    if (staffList.isNotEmpty) {
      minDistance = Geolocator.distanceBetween(
        incident.location.lat, incident.location.long,
        staffList.first.location.latitude, staffList.first.location.longitude
      );
    }
    final color = incident.severity >= 8 ? Colors.redAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.my_location, color: color, size: 14),
            const SizedBox(width: 8),
            const Text("SELECTED INCIDENT", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const Spacer(),
            GestureDetector(onTap: onClose, child: const Icon(Icons.close, color: Colors.white38, size: 18)),
          ]),
          const SizedBox(height: 10),
          Text("${incident.type.toUpperCase()} EMERGENCY", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(children: [
            _tag("Floor ${incident.location.floor}", Colors.white10, Colors.white60),
            const SizedBox(width: 6),
            _tag("Sev ${incident.severity}/10", color.withOpacity(0.2), color),
            const SizedBox(width: 6),
            _tag(incident.status.toUpperCase(), Colors.white10, Colors.white60),
            if (incident.assignedTo != null) ...[
              const SizedBox(width: 6),
              _tag("→ ${incident.assignedTo}", Colors.green.withOpacity(0.15), Colors.greenAccent),
            ],
          ]),
          if (incident.aiAnalysis != null) ...[
            const SizedBox(height: 8),
            Text("🤖 ${incident.aiAnalysis}", style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          
          // ── LIVE EVIDENCE SECTION ──
          if (incident.status == 'Capturing' || incident.evidenceImages != null || incident.evidenceAudio != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("LIVE EVIDENCE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                if (incident.status == 'Capturing') ...[
                  const SizedBox(width: 8),
                  _BlinkingDot(),
                  const SizedBox(width: 4),
                  const Text("CAPTURING...", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
            const SizedBox(height: 10),
            
            if (incident.status == 'Capturing' && incident.evidenceImages == null)
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
                    SizedBox(height: 8),
                    Text("Awaiting Media Witness...", style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),

            if (incident.evidenceImages != null)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: incident.evidenceImages!.length,
                  itemBuilder: (context, idx) => Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: NetworkImage(incident.evidenceImages![idx]), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            if (incident.evidenceAudio != null)
              _AudioEvidencePlayer(url: incident.evidenceAudio!),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.radar, color: Colors.blueAccent, size: 14),
              const SizedBox(width: 8),
              Text(
                minDistance >= 0 
                  ? "PROXIMITY: ${minDistance.toStringAsFixed(0)}m TO RESPONDER" 
                  : "TRACKING RESPONDER...",
                style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _AudioEvidencePlayer extends StatefulWidget {
  final String url;
  const _AudioEvidencePlayer({required this.url});

  @override
  State<_AudioEvidencePlayer> createState() => _AudioEvidencePlayerState();
}

class _AudioEvidencePlayerState extends State<_AudioEvidencePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.blueAccent),
            onPressed: () async {
              if (_isPlaying) {
                await _player.pause();
              } else {
                await _player.play(UrlSource(widget.url));
              }
              setState(() => _isPlaying = !_isPlaying);
            },
          ),
          const Expanded(
            child: Text("VOICE WITNESS CLIP (10s)", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          if (_isPlaying) const Icon(Icons.graphic_eq, color: Colors.blueAccent, size: 16),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  __BlinkingDotState createState() => __BlinkingDotState();
}

class __BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    super.initState();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
    );
  }
}
