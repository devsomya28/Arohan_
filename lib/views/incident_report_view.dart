import 'package:flutter/material.dart';

class IncidentReportView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Color(0xFF0B1220),
        elevation: 0,
        leading: Icon(Icons.diamond, color: Color(0xFF6366F1)),
        title: Text("COMMAND CENTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
        actions: [Icon(Icons.notifications_none, color: Colors.indigoAccent), SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("POST-INCIDENT ANALYTICS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            SizedBox(height: 8),
            Text("Incident #4920\nSummary", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1)),
            SizedBox(height: 16),
            Row(
              children: [
                _buildSmallBadge("FLOOR 3 FIRE", Colors.red),
                SizedBox(width: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white38, size: 14),
                    SizedBox(width: 8),
                    Text("Oct 24, 2023", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildExportBtn(),
            SizedBox(height: 24),
            _buildMetricCard("Mean Response Time", "1m 45s", "42% faster than facility average", Icons.timer_outlined),
            SizedBox(height: 12),
            _buildMetricCard("Compliance", "100%", "(NDMA India) Protocol met", Icons.verified_user_outlined),
            SizedBox(height: 12),
            _buildMetricCard("Casualties", "0", "Full evacuation successful", Icons.person_off_outlined),
            SizedBox(height: 32),
            _buildTimelineSection(),
            SizedBox(height: 32),
            _buildSpatialFocus(),
            SizedBox(height: 32),
            _buildTechnicalLog(),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildExportBtn() {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(color: Color(0xFFC7D2FE), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.black87, size: 18),
          SizedBox(width: 12),
          Text("Export PDF Report", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Color(0xFF1E293B).withOpacity(0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              Text(sub, style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
          Icon(icon, color: Colors.white10, size: 64),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("INCIDENT TIMELINE", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        SizedBox(height: 24),
        _timelineItem("10:00:00", "Sensor Triggered", "Smoke detector Zone 3B activated.", Colors.redAccent),
        _timelineItem("10:00:05", "AI Triage Confirmed", "Visual verification via Cam 094.", Colors.orangeAccent),
        _timelineItem("10:01:50", "Responder ACK", "Fire Marshall Unit 2 on scene.", Colors.indigoAccent),
      ],
    );
  }

  Widget _timelineItem(String time, String title, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)])),
              Container(width: 2, height: 40, color: Colors.white10),
            ],
          ),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text(sub, style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpatialFocus() {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1541888941259-7b3b9d17d4a4?q=80&w=2000"), fit: BoxFit.cover, opacity: 0.1),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Spatial Focus", style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                    Text("South Wing - Corridor B", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                  Row(children: [
                    Icon(Icons.center_focus_strong, color: Colors.indigoAccent, size: 20),
                    SizedBox(width: 12),
                    Icon(Icons.map_outlined, color: Colors.white30, size: 20),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalLog() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("TECHNICAL\nSEQUENCE LOG", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text("128 TOTAL EVENTS", style: TextStyle(color: Colors.indigoAccent, fontSize: 8, fontWeight: FontWeight.bold))),
          ],
        ),
        SizedBox(height: 24),
        _logHeader(),
        _logRow("10:00:00.002", "DET-03-B-012", Colors.orangeAccent),
        _logRow("10:00:00.045", "CORE_ROUT_01", Colors.indigoAccent),
        _logRow("10:00:05.110", "AI_VIS_ENGINE", Colors.orangeAccent),
      ],
    );
  }

  Widget _logHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(children: [
        Expanded(flex: 3, child: Text("TIMESTAMP", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text("SYSTEM UNIT", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text("ACTION", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _logRow(String time, String unit, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      border: Border(bottom: BorderSide(color: Colors.white10)),
      child: Row(children: [
        Expanded(flex: 3, child: Text(time, style: TextStyle(color: Colors.white, fontSize: 11))),
        Expanded(flex: 3, child: Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 8),
          Text(unit, style: TextStyle(color: Colors.white, fontSize: 11)),
        ])),
        Expanded(flex: 3, child: Text("Log Entry Data...", style: TextStyle(color: Colors.white38, fontSize: 11))),
      ]),
    );
  }
}
