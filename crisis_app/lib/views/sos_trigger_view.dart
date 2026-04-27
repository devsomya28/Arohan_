import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../viewmodels/guest_viewmodel.dart';
import 'guest_home_view.dart';
import 'profile_view.dart';

class SosTriggerView extends StatefulWidget {
  @override
  _SosTriggerViewState createState() => _SosTriggerViewState();
}

class _SosTriggerViewState extends State<SosTriggerView> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _secondsRemaining = 120; // 2 minutes
  Timer? _timer;
  late AnimationController _pulseController;
  String _startTimeStr = "";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerEmergency(GuestViewModel vm) {
    if (_isRecording) return;
    
    // Trigger Twilio SMS and Incident Creation via backend without navigating away
    vm.triggerSOS(context: context, navigateToCamera: false);
    
    setState(() {
      _isRecording = true;
      _secondsRemaining = 120;
      final now = DateTime.now();
      int h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      String amPm = now.hour >= 12 ? 'PM' : 'AM';
      _startTimeStr = '${h}:${now.minute.toString().padLeft(2, '0')} $amPm';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Emergency Recording Complete and Sent."), backgroundColor: Colors.green)
        );
      }
    });
  }

  String get _timerText {
    int m = _secondsRemaining ~/ 60;
    int s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GuestViewModel>();

    if (_isRecording) {
      return _buildActiveEmergencySession();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF040A15), // Cinematic navy blue
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text("EMERGENCY OVERRIDE", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Dramatic Red Card
            GestureDetector(
              onTap: () => _triggerEmergency(vm),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 260,
                    height: 320,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3B30), Color(0xFF990000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(_isRecording ? 0.8 : 0.4 + (_pulseController.value * 0.2)),
                          blurRadius: _isRecording ? 60 : 40,
                          spreadRadius: _isRecording ? 20 : 10,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRecording)
                          Text(_timerText, style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()]))
                        else
                          const Icon(Icons.podcasts, color: Colors.white, size: 100), // Location pin with signal waves (sensors/podcasts)
                        const SizedBox(height: 32),
                        Text(
                          _isRecording ? "RECORDING AUDIO..." : "TRIGGER SOS",
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                        if (!_isRecording) ...[
                          const SizedBox(height: 12),
                          const Text("TAP TO ACTIVATE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ]
                      ],
                    ),
                  );
                }
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Info Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoBadge(Icons.mic_none, "2-MIN EMERGENCY\nRECORDING"),
                const SizedBox(width: 40),
                _infoBadge(Icons.sms_failed_outlined, "SMS & WHATSAPP\nTO STAFF (TWILIO)"),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Bottom Nav
            _buildBottomNavBar(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: Colors.white70, size: 28),
        ),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, height: 1.5)),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 10),
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_filled, color: Colors.white.withOpacity(0.4), size: 28),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfileView()));
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, color: Colors.white.withOpacity(0.4), size: 28),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // HIGHLIGHTED CENTER SOS SHIELD
          Positioned(
            top: -25,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE63946),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2), // Highlighted with white border
                boxShadow: [
                  BoxShadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 25, spreadRadius: 5),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, color: Colors.white, size: 32),
                  Text("SOS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActiveEmergencySession() {
    int durationSecs = 120 - _secondsRemaining;
    String durationText = '${(durationSecs ~/ 60).toString().padLeft(2, '0')}:${(durationSecs % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          children: [
            // Top Status Bar (Bright Red Flashing)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  color: Colors.redAccent.withOpacity(0.5 + (_pulseController.value * 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: const Text(
                    "● RECORDING START",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3),
                  ),
                );
              }
            ),
            
            const SizedBox(height: 16),
            const Text("ACTIVE EMERGENCY SESSION", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),

            // Main Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  _infoRow("Started", _startTimeStr),
                  const SizedBox(height: 16),
                  _infoRow("Duration", durationText),
                  const SizedBox(height: 16),
                  _infoRow("Location", "23.261, 77.500"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Large Digital Timer
            Text(
              _timerText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()]
              ),
            ),
            const Text("REMAINING", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4)),

            const SizedBox(height: 30),

            // Bottom Prominent Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _timer?.cancel();
                        setState(() => _isRecording = false);
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        alignment: Alignment.center,
                        child: const Text("STOP RECORDING", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _timer?.cancel();
                        setState(() => _isRecording = false);
                        Navigator.pop(context); // Go back home
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 20)],
                        ),
                        alignment: Alignment.center,
                        child: const Text("I AM SAFE", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}
