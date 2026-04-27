import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/staff.dart';

class ProximityService {
  StreamSubscription? _proximitySubscription;

  /// Starts listening to staff locations and calculates distance to the guest's SOS
  void startProximityTracking({
    required double guestLat,
    required double guestLong,
    required String incidentId,
    required Function(double distance, StaffMember nearestStaff) onUpdate,
    required Function() onArrived,
  }) {
    _proximitySubscription?.cancel();

    // Listen to real-time staff updates from Firestore
    _proximitySubscription = FirebaseFirestore.instance
        .collection('staff')
        .snapshots()
        .listen((snapshot) {
      
      StaffMember? nearestStaff;
      double minDistance = double.infinity;

      for (var doc in snapshot.docs) {
        final staff = StaffMember.fromFirestore(doc);
        
        // Calculate distance between Guest and this Staff member
        double distance = Geolocator.distanceBetween(
          guestLat, guestLong,
          staff.location.latitude, staff.location.longitude
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestStaff = staff;
        }
      }

      if (nearestStaff != null) {
        // Trigger UI updates with live distance
        onUpdate(minDistance, nearestStaff);

        // 🚨 PROXIMITY TRIGGER: Change status if < 100m
        if (minDistance < 100) {
          _updateIncidentStatus(incidentId, "First Responder On-Site");
          onArrived();
          _proximitySubscription?.cancel(); // Stop tracking once arrived
        }
      }
    });
  }

  Future<void> _updateIncidentStatus(String incidentId, String status) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref("incidents/$incidentId");
      await dbRef.update({
        "status": status,
        "arrived_timestamp": DateTime.now().toUtc().toIso8601String(),
      });
      print("🚨 PROXIMITY ALERT: Incident #$incidentId status updated to $status");
    } catch (e) {
      print("Proximity Status Update Failed: $e");
    }
  }

  void stopTracking() {
    _proximitySubscription?.cancel();
  }
}
