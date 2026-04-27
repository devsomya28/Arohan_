import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/staff.dart';

class StaffTrackingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;

  /// Starts tracking the staff member and updating Firestore
  Future<void> startTracking(String staffId) async {
    // 1. Request Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Setup Location Stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      _updateLocationInFirestore(staffId, position);
    });
  }

  /// Pushes coordinates to the Digital Twin in Firestore
  Future<void> _updateLocationInFirestore(String staffId, Position position) async {
    try {
      await _db.collection('staff').doc(staffId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'last_seen': FieldValue.serverTimestamp(),
        'status': 'available',
      });
      print("Digital Twin: Staff $staffId location updated.");
    } catch (e) {
      print("Digital Twin Sync Error: $e");
      // If doc doesn't exist, create a basic profile
      await _db.collection('staff').doc(staffId).set({
        'name': 'Staff Member',
        'skillsets': ['fire', 'medical'],
        'location': GeoPoint(position.latitude, position.longitude),
        'last_seen': FieldValue.serverTimestamp(),
        'status': 'available',
      }, SetOptions(merge: true));
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
  }
}
