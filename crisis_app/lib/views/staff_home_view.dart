import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/staff_viewmodel.dart';
import 'commander_map_view.dart';
import 'incident_map_view.dart';
import 'guest_home_view.dart';
import 'camera_upload_view.dart';
import '../services/api_service.dart';
import '../models/incident.dart';

class StaffHomeView extends StatefulWidget {
  @override
  _StaffHomeViewState createState() => _StaffHomeViewState();
}

class _StaffHomeViewState extends State<StaffHomeView> {
  int _currentIndex = 1;

  void _showTestSnackBar(BuildContext context, String message, {Color color = Colors.indigoAccent}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_currentIndex) {
      case 0: bodyContent = CommanderMapView(); break;
      case 1: bodyContent = _buildIncidentDetailContent(context); break;
      case 2: bodyContent = IncidentMapView(); break;
      case 3: bodyContent = GuestHomeView(); break;
      default: bodyContent = Center(child: Text("ERROR"));
    }

    return Scaffold(
      backgroundColor: Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Color(0xFF0B1220),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.diamond, color: Color(0xFF6366F1)),
          onPressed: () => _showTestSnackBar(context, "AOCC System: Diagnostic Check Passed"),
        ),
        title: Text("COMMAND CENTER", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white38, size: 18),
            onPressed: () async {
              await ApiService().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildIncidentDetailContent(BuildContext context) {
    final vm = context.watch<StaffViewModel>();
    final incidents = vm.activeIncidents;

    if (vm.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6366F1)),
            SizedBox(height: 16),
            Text("Syncing with Firebase...", style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    if (incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text("No active incidents", style: TextStyle(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("All clear. Monitoring live Firebase stream.", style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        bool isMedium = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
        
        int crossAxisCount = isWide ? 3 : (isMedium ? 2 : 1);
        double childAspectRatio = isWide ? 1.1 : (isMedium ? 1.2 : 1.3);

        if (crossAxisCount > 1) {
          return GridView.builder(
            padding: EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMainCard(incident, context),
                    SizedBox(height: 12),
                    _buildAIAnalysis(incident),
                  ],
                ),
              );
            },
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: incidents.length + 1,
          itemBuilder: (context, index) {
            if (index == incidents.length) {
              return Padding(
                padding: EdgeInsets.only(top: 24),
                child: _buildAuditTrail(incidents),
              );
            }
            final incident = incidents[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  _buildMainCard(incident, context),
                  SizedBox(height: 12),
                  _buildAIAnalysis(incident),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainCard(dynamic incident, BuildContext context) {
    bool isAssigned = incident.status == "assigned";
    bool isHighSeverity = (incident.severity ?? 0) >= 8;

    IconData typeIcon;
    Color typeColor;
    switch (incident.type.toLowerCase()) {
      case 'fire': typeIcon = Icons.local_fire_department; typeColor = Colors.orangeAccent; break;
      case 'medical': typeIcon = Icons.medical_services; typeColor = Colors.redAccent; break;
      default: typeIcon = Icons.emergency; typeColor = Color(0xFF6366F1);
    }

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighSeverity ? Colors.redAccent.withOpacity(0.5) : (isAssigned ? Color(0xFF10B981).withOpacity(0.3) : Colors.white10),
          width: isHighSeverity ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(typeIcon, color: typeColor, size: 16),
                SizedBox(width: 8),
                Text("INCIDENT ID: #${incident.id ?? 'UNKNOWN'}", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                if (isHighSeverity)
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                    child: Text("CRITICAL", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAssigned ? Color(0xFF10B981).withOpacity(0.1) : (isHighSeverity ? Colors.redAccent.withOpacity(0.1) : Colors.white10),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isAssigned ? Color(0xFF10B981) : (isHighSeverity ? Colors.redAccent : Colors.white24), width: 0.5),
                  ),
                  child: Text(
                    isAssigned ? "ASSIGNED" : "ACTIVE",
                    style: TextStyle(color: isAssigned ? Color(0xFF10B981) : (isHighSeverity ? Colors.redAccent : Colors.white), fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "${incident.type.toUpperCase()}\nEMERGENCY",
            style: TextStyle(
              color: isHighSeverity ? Colors.redAccent : Colors.white,
              fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1,
            ),
          ),
          SizedBox(height: 24),

          // ACCEPT + ESCALATE
          Row(children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAssigned ? Colors.blueGrey.withOpacity(0.5) : (isHighSeverity ? Colors.redAccent : Color(0xFF10B981)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isAssigned ? null : () => context.read<StaffViewModel>().acceptIncidentAction(incident.id!, context),
                child: Text(isAssigned ? "ASSIGNED" : "ACCEPT MISSION", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFEF4444)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => context.read<StaffViewModel>().escalateIncidentAction(incident.id!, context),
                child: Text("ESCALATE", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              ),
            ),
          ]),

          SizedBox(height: 12),

          // ── LIVE MEDIA SECTION ──
          if (incident.status == 'Capturing' || incident.evidenceImages != null || incident.evidenceAudio != null) ...[
            SizedBox(height: 16),
            _buildLiveMediaSection(incident),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAnalysis(dynamic incident) {
    bool isHighSeverity = (incident.severity ?? 0) >= 8;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighSeverity ? Colors.redAccent.withOpacity(0.05) : Color(0xFF1E293B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighSeverity ? Colors.redAccent.withOpacity(0.2) : Colors.white10),
      ),
      child: Row(children: [
        Icon(Icons.auto_awesome, color: isHighSeverity ? Colors.redAccent : Colors.indigoAccent),
        SizedBox(width: 16),
        Expanded(child: Text("GEMINI AI: ${incident.aiAnalysis ?? 'Analyzing situation...'}", style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic))),
      ]),
    );
  }

  Widget _buildAuditTrail(List<dynamic> incidents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("AUDIT LOG", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ...incidents.map((i) => Text("• ${i.type.toUpperCase()} alert triggered at ${i.timestamp}", style: TextStyle(color: Colors.white38, fontSize: 10))).toList(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      color: Color(0xFF0F172A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view, "DASHBOARD", 0),
          _navItem(Icons.emergency, "INCIDENTS", 1),
          _navItem(Icons.map, "MAPS", 2),
          _navItem(Icons.person, "GUEST", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Color(0xFF6366F1) : Colors.white24, size: 24),
            SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? Color(0xFF6366F1) : Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMediaSection(dynamic incident) {
    bool isCapturing = (incident is Incident) ? (incident.status == 'Capturing') : (incident['status'] == 'Capturing');
    
    List<dynamic>? images;
    String? audio;
    
    if (incident is Incident) {
      images = incident.evidenceImages;
      audio = incident.evidenceAudio;
    } else {
      images = incident['evidence_images'] as List?;
      audio = incident['evidence_audio']?.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("LIVE EVIDENCE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            if (isCapturing) ...[
              SizedBox(width: 8),
              _BlinkingDot(),
              SizedBox(width: 4),
              Text("CAPTURING...", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
        SizedBox(height: 10),
        
        if (isCapturing && images == null)
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
                SizedBox(height: 8),
                Text("Awaiting Media Witness...", style: TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),

        if (images != null)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images!.length,
              itemBuilder: (context, idx) => Container(
                width: 100,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(image: NetworkImage(images![idx]), fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        
        if (audio != null)
          Container(
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.graphic_eq, color: Color(0xFF6366F1), size: 20),
                SizedBox(width: 12),
                Text("VOICE WITNESS READY (10s)", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                Spacer(),
                Icon(Icons.play_circle, color: Color(0xFF6366F1)),
              ],
            ),
          ),
      ],
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
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 600))..repeat(reverse: true);
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
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
    );
  }
}

