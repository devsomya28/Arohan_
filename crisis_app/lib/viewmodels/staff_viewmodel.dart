import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';
import '../models/location.dart';
import '../models/staff.dart';
import '../services/api_service.dart';

class StaffViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Incident> _activeIncidents = [];
  List<Incident> get activeIncidents => _activeIncidents;

  List<StaffMember> _activeStaff = [];
  List<StaffMember> get activeStaff => _activeStaff;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription? _incidentSubscription;
  StreamSubscription? _staffSubscription;

  StaffViewModel() {
    print("StaffViewModel: Initializing Real-Time Sync...");
    _startFirebaseSync();
    _startStaffTracking();
  }

  void _startStaffTracking() {
    _staffSubscription = FirebaseFirestore.instance
        .collection('staff')
        .snapshots()
        .listen((snapshot) {
      _activeStaff = snapshot.docs.map((doc) => StaffMember.fromFirestore(doc)).toList();
      notifyListeners();
      print("Digital Twin: ${_activeStaff.length} staff members online.");
    });
  }

  void _startFirebaseSync() {
    try {
      print("Firebase: Subscribing to 'incidents' node...");
      final dbRef = FirebaseDatabase.instance.ref("incidents");
      
      _incidentSubscription = dbRef.onValue.listen((event) {
        final Object? dataValue = event.snapshot.value;
        
        if (dataValue != null && dataValue is Map) {
          final List<Incident> updatedList = [];
          
          dataValue.forEach((key, value) {
            try {
              if (value is Map) {
                final Map<String, dynamic> json = Map<String, dynamic>.from(value);
                json['id'] ??= key.toString();
                updatedList.add(Incident.fromJson(json));
              }
            } catch (e) {
              print("StaffVM: Item Parsing Error: $e");
            }
          });
          
          // Sort by timestamp (newest first)
          updatedList.sort((a, b) => (b.timestamp ?? '').compareTo(a.timestamp ?? ''));
          
          _activeIncidents = updatedList;
          notifyListeners();
          print("Firebase: Sync Complete. ${updatedList.length} incidents loaded.");
        } else {
          print("Firebase: Node is empty or invalid data format.");
          _activeIncidents = [];
          notifyListeners();
        }
      }, onError: (error) {
        print("Firebase: Subscription Error: $error");
      });
    } catch (e) {
      print("Firebase: Sync Initialization Failed: $e");
    }
  }

  // MISSION ACCEPTANCE
  Future<void> acceptIncidentAction(String incidentId, BuildContext context) async {
    try {
      print("ViewModel: Accepting Mission $incidentId");

      // Call Backend API — Firebase RTDB will update via backend and
      // the onValue listener will refresh the list automatically
      final success = await _apiService.acknowledgeIncident(incidentId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("MISSION ACCEPTED: You are now assigned to #$incidentId"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server could not acknowledge this incident. Try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      print("Accept Mission Failed: $e");
    }
  }

  Future<void> escalateIncidentAction(String incidentId, BuildContext context) async {
    try {
      print("ViewModel: Escalating Incident $incidentId");
      final success = await _apiService.escalateIncident(incidentId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("CRITICAL ALERT: Incident #$incidentId escalated to national 112 services."),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      print("Escalation Failed: $e");
    }
  }

  // addLocalIncident removed — incident list is strictly Firebase-sourced

  @override
  void dispose() {
    _incidentSubscription?.cancel();
    _staffSubscription?.cancel();
    super.dispose();
  }
}
