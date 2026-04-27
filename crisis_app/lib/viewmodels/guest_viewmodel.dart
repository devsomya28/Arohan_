import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import '../views/camera_upload_view.dart' as camera;
import 'package:geolocator/geolocator.dart';
import '../services/sos_capture_service.dart';

class GuestViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SOSCaptureService _mediaService = SOSCaptureService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Stores the most recent incident ID so guest can attach a photo
  String? _lastIncidentId;
  String? get lastIncidentId => _lastIncidentId;

  double _currentLat = 28.6139; // Default (Delhi)
  double _currentLong = 77.2090;
  double get currentLat => _currentLat;
  double get currentLong => _currentLong;

  /// Stores a history of SOS triggers with their timestamps
  final List<Map<String, dynamic>> _sosHistory = [];
  List<Map<String, dynamic>> get sosHistory => _sosHistory;

  int _unreadNotifications = 0;
  int get unreadNotifications => _unreadNotifications;

  void clearNotifications() {
    _unreadNotifications = 0;
    notifyListeners();
  }

  GuestViewModel() {
    startLocationTracking();
  }

  Future<void> startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Get initial position
    try {
      Position position = await Geolocator.getCurrentPosition();
      _currentLat = position.latitude;
      _currentLong = position.longitude;
      notifyListeners();
    } catch (e) {
      print("Location error: $e");
    }

    // Listen for updates
    Geolocator.getPositionStream(locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    )).listen((Position position) {
      _currentLat = position.latitude;
      _currentLong = position.longitude;
      notifyListeners();
    });
  }

  Future<void> triggerSOS({SOSCreate? manualSos, BuildContext? context, bool navigateToCamera = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      print("GUEST: Triggering SOS — Writing directly to Firebase RTDB...");

      final String? userId = await _apiService.getUserId();
      final DateTime now = DateTime.now();
      final String timestamp = now.toUtc().toIso8601String();
      final String readableTime = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final location = {'lat': _currentLat, 'long': _currentLong, 'floor': 1};

      // Add to local history for the "Bell" view
      _sosHistory.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'emergency',
        'time': readableTime,
        'status': 'Sending...',
      });
      _unreadNotifications++;
      notifyListeners();

      // 1. Load Guardian Numbers (Try Cloud first, then local cache)
      List<String> guardianNumbers = [];
      if (userId != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(userId!).get();
          if (doc.exists && doc.data() != null) {
            final cloudPhones = doc.data()!['guardian_numbers'] as List?;
            if (cloudPhones != null) {
              guardianNumbers = List<String>.from(cloudPhones.map((p) => p.toString()));
            }
          }
        } catch (e) {
          print("Cloud Fetch Error during SOS: $e");
        }
      }

      if (guardianNumbers.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        guardianNumbers = prefs.getStringList('guardian_numbers') ?? [];
      }
      
      List<String> formattedPhones = [];
      for (String phone in guardianNumbers) {
        if (phone != "No Number Set" && phone.isNotEmpty) {
          String p = phone.trim();
          if (!p.startsWith('+')) {
            p = '+$p';
          }
          formattedPhones.add(p);
        }
      }

      // 1. Immediately trigger the Backend AI triage and Twilio SMS!
      _apiService.sendSos(
        SOSCreate(
          userId: userId ?? "guest_user_123",
          location: Location(lat: _currentLat, long: _currentLong, floor: 1),
          emergencyType: "emergency",
          phone: formattedPhones.isNotEmpty ? formattedPhones : null,
        ),
      ).catchError((e) {
        print("Background backend triage failed (non-critical): $e");
      });

      // Write to Firebase RTDB for instant dashboard update
      final dbRef = FirebaseDatabase.instance.ref("incidents");
      final newRef = dbRef.push();

      final incidentData = {
        'id': newRef.key,
        'type': 'emergency',
        'severity': 9,
        'severity_label': 'high',
        'status': 'Capturing', // Media Sentinel Initial State
        'source': 'guest_sos',
        'timestamp': timestamp,
        'user_id': userId ?? "guest_user_123",
        'location': location,
        'escalated': false,
        'ai_analysis': 'SOS triggered by guest. Awaiting AI triage...',
        'assigned_to': null,
        if (formattedPhones.isNotEmpty) 'phone': formattedPhones.join(', '),
      };

      await newRef.set(incidentData);
      _lastIncidentId = newRef.key;
      notifyListeners();

      // 🚨 START MEDIA WITNESS (Background)
      if (_lastIncidentId != null) {
        _mediaService.captureEmergencyEvidence(_lastIncidentId!).then((evidence) {
          // Update Firebase with media URLs once captured
          newRef.update({
            'evidence_images': evidence['images'],
            'evidence_audio': evidence['audio'],
            'status': 'Evidence_Ready', // Media Sentinel Complete
            'capture_complete': true,
          });
          
          // 🧠 TRIGGER GEMINI VISION ANALYSIS
          if (evidence['images'] != null && (evidence['images'] as List).isNotEmpty) {
            _apiService.processVisualTriage(_lastIncidentId!, List<String>.from(evidence['images']));
          }
          
          print("🚨 MEDIA WITNESS: Evidence uploaded and AI Triage triggered for incident ${_lastIncidentId}");
        });
      }

      print("Firebase RTDB: Incident written → ${newRef.key}");

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SOS sent! Emergency protocols activated."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          )
        );
        if (navigateToCamera) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => 
            camera.CameraUploadView(incidentId: newRef.key!, incidentType: 'emergency')
          ));
        }
      }

      // Firebase write is now done AFTER the backend is triggered.

    } catch (e) {
      print("SOS Failure: $e");
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send SOS. Please try again.\n$e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkInSafeAction(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Status updated: You are marked SAFE."),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      )
    );
  }
}
