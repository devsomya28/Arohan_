import 'package:flutter/material.dart';

class AnalyticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildHeaderSection()),
          SliverToBoxAdapter(child: _buildExportButton()),
          SliverToBoxAdapter(child: _buildKeyMetricsList()),
          SliverToBoxAdapter(child: _buildTimelineSection()),
          SliverToBoxAdapter(child: _buildSpatialFocusSection()),
          SliverToBoxAdapter(child: _buildTechnicalLogSection()),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
      leading: Icon(Icons.diamond_outlined, color: Colors.indigoAccent),
      title: Text("COMMAND CENTER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, size: 18, color: Colors.white24),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
        Icon(Icons.notifications_active, color: Colors.indigoAccent),
        SizedBox(width: 16)
      ],
      pinned: true,
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("POST-INCIDENT ANALYTICS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          SizedBox(height: 8),
          Text("Incident #4920\nSummary", style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.1)),
          SizedBox(height: 16),
          Row(
            children: [
              _buildBadge("FLOOR 3 FIRE", Colors.redAccent, isFilled: true),
              SizedBox(width: 12),
              _buildBadge("Oct 24, 2023", Colors.white, icon: Icons.calendar_today),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {bool isFilled = false, IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled ? Color(0xFF8B0000) : Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: Colors.white70), SizedBox(width: 6)],
          Text(text, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFF1E293B)),
        label: Text("Export PDF Report", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFC7D2FE), // Lavender color from design
          minimumSize: Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildKeyMetricsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        children: [
          _buildMetricCard("Mean Response Time", "1m 45s", "42% faster than facility average", Icons.timer_outlined),
          SizedBox(height: 16),
          _buildMetricCard("Compliance", "100%", "(NDMA India) Protocol met", Icons.verified_user_outlined),
          SizedBox(height: 16),
          _buildMetricCard("Casualties", "0", "Full evacuation successful", Icons.person_off_outlined),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, color: Colors.white.withOpacity(0.05), size: 80),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.white30, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: Colors.indigoAccent),
              SizedBox(width: 12),
              Text("INCIDENT TIMELINE", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          SizedBox(height: 24),
          _buildTimelineItem("10:00:00", "Sensor Triggered", "Smoke detector Zone 3B activated.", Color(0xFFFCA5A5)),
          _buildTimelineItem("10:00:05", "AI Triage Confirmed", "Visual verification via Cam 094.", Color(0xFFFDBA74)),
          _buildTimelineItem("10:01:50", "Responder ACK", "Fire Marshall Unit 2 on scene.", Color(0xFFC7D2FE)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String time, String title, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            ),
            Container(width: 1, height: 50, color: Colors.white10),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(desc, style: TextStyle(color: Colors.white54, fontSize: 13)),
              SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpatialFocusSection() {
    return Container(
      margin: EdgeInsets.all(24),
      height: 280,
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=2000"), // Floor plan image
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Spatial Focus", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("South Wing - Corridor B", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Icon(Icons.layers_outlined, color: Colors.indigoAccent, size: 20),
                  SizedBox(width: 8),
                  Icon(Icons.security, color: Colors.white24, size: 20),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTechnicalLogSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TECHNICAL\nSEQUENCE LOG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: Text("128 TOTAL EVENTS", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          SizedBox(height: 24),
          _buildLogTable(),
        ],
      ),
    );
  }

  Widget _buildLogTable() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text("TIMESTAMP", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text("SYSTEM UNIT", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text("ACTION", textAlign: TextAlign.right, style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold))),
          ],
        ),
        Divider(color: Colors.white10),
        _buildLogRow("10:00:00.002", "DET-03-B-012", "STR-AL", Colors.orangeAccent),
        _buildLogRow("10:00:00.045", "CORE_ROUT_01", "UPLINK", Colors.indigoAccent),
        _buildLogRow("10:00:05.110", "AI_VIS_ENGINE", "CONF98", Colors.orangeAccent),
      ],
    );
  }

  Widget _buildLogRow(String time, String unit, String action, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(time, style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'))),
          Expanded(flex: 3, child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Text(unit, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )),
          Expanded(flex: 2, child: Text(action, textAlign: TextAlign.right, style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
