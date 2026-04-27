import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camera_upload_view.dart';
import '../viewmodels/guest_viewmodel.dart';
import 'dart:math';
import 'sos_trigger_view.dart';
import 'profile_view.dart';

class GuestHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GuestViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ]
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _buildTopBar(vm),
                      const SizedBox(height: 20),
                      _buildRiskGauge(),
                      const SizedBox(height: 20),
                      // Map Section
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double screenHeight = MediaQuery.of(context).size.height;
                          double mapHeight = screenHeight > 800 ? 500 : 400;
                          return Container(
                            width: double.infinity,
                            height: mapHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: _buildRadarMap(vm),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 120), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavBar(vm, context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(GuestViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Arohan Ai", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text("Secure Companion", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          _NotificationBell(vm: vm),
        ],
      ),
    );
  }

  Widget _buildRiskGauge() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing ring
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 30, spreadRadius: 5),
                ],
              ),
            ),
            // Inner gauge ring
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent.withOpacity(0.8)),
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            // Text center
            Column(
              children: [
                Text("RISK LEVEL", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 4),
                const Text("0%", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                const Text("SAFE", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildRadarMap(GuestViewModel vm) {
    // Zoom level 15
    const int zoom = 15;
    final n = pow(2, zoom);
    
    // Calculate OSM tile coordinates
    final int xTile = (n * ((vm.currentLong + 180) / 360)).floor();
    final double latRad = vm.currentLat * pi / 180;
    final int yTile = (n * (1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2).floor();

    // We fetch a 3x3 grid of tiles to allow for smooth centering
    return Stack(
      children: [
        // Map Tiles Grid
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final int dx = (index % 3) - 1;
            final int dy = (index ~/ 3) - 1;
            final String url = 'https://tile.openstreetmap.org/$zoom/${xTile + dx}/${yTile + dy}.png';
            
            return Image.network(
              url,
              fit: BoxFit.cover, 
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            );
          },
        ),
        
        // Location Marker Overlay
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: const Text("YOUR LOCATION", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.location_on, color: Colors.blueAccent, size: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(GuestViewModel vm, BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // HOME ICON (Active Blue)
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_filled, color: Colors.blueAccent, size: 28),
                    const SizedBox(height: 4),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
                  ],
                ),
              ),
              // PROFILE ICON
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileView()));
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, color: Colors.white.withOpacity(0.4), size: 28),
                      const SizedBox(height: 4),
                      const SizedBox(height: 4), // Placeholder for dot
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // CENTER SOS SHIELD
          Positioned(
            top: -25,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SosTriggerView()));
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE63946),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF131B2A), width: 6),
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield, color: Colors.white, size: 32),
                        Text("SOS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Simulated map drawing "Near Safe Peoples"
class _RadarMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw Map Grid
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw Radar Rings
    final ringPaint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawCircle(center, 60, ringPaint);
    canvas.drawCircle(center, 120, ringPaint);
    canvas.drawCircle(center, 180, ringPaint);

    // My Location (Center)
    final myLocationPaint = Paint()..color = Colors.greenAccent..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, myLocationPaint);
    canvas.drawCircle(center, 20, Paint()..color = Colors.greenAccent.withOpacity(0.2));

    // Draw Mock People (Blue: Staff, Red: Emergency, Orange: Guests)
    _drawPerson(canvas, center, Offset(-40, -50), Colors.blueAccent); // Staff
    _drawPerson(canvas, center, Offset(80, -30), Colors.orangeAccent); // Guest
    _drawPerson(canvas, center, Offset(20, 90), Colors.orangeAccent); // Guest
    _drawPerson(canvas, center, Offset(-90, 60), Colors.blueAccent); // Staff
    _drawPerson(canvas, center, Offset(110, 100), Colors.redAccent); // Emergency
    _drawPerson(canvas, center, Offset(-120, -100), Colors.redAccent); // Emergency
  }

  void _drawPerson(Canvas canvas, Offset center, Offset offset, Color color) {
    final pos = center + offset;
    canvas.drawCircle(pos, 6, Paint()..color = color);
    canvas.drawCircle(pos, 14, Paint()..color = color.withOpacity(0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NotificationBell extends StatefulWidget {
  final GuestViewModel vm;
  const _NotificationBell({required this.vm});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(covariant _NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vm.unreadNotifications > oldWidget.vm.unreadNotifications) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showHistorySheet(BuildContext context, GuestViewModel vm) {
    vm.clearNotifications();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1421),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text("INCIDENT HISTORY", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            Expanded(
              child: vm.sosHistory.isEmpty
                ? Center(child: Text("No incident history yet.", style: TextStyle(color: Colors.white.withOpacity(0.3))))
                : ListView.builder(
                    itemCount: vm.sosHistory.length,
                    itemBuilder: (context, index) {
                      final item = vm.sosHistory[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.sos, color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Emergency SOS Triggered", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("Status: Active Response", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(item['time'], style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHistorySheet(context, widget.vm),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double shake = sin(_controller.value * pi * 4) * 5;
          return Transform.translate(
            offset: Offset(shake, 0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.vm.unreadNotifications > 0 ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                  ),
                  child: Icon(
                    widget.vm.unreadNotifications > 0 ? Icons.notifications_active : Icons.notifications_none,
                    color: widget.vm.unreadNotifications > 0 ? Colors.redAccent : Colors.white,
                    size: 22,
                  ),
                ),
                if (widget.vm.unreadNotifications > 0)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: Center(child: Text("${widget.vm.unreadNotifications}", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
