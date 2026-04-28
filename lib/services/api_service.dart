import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';

class ApiService {
  // Base URL — change to your actual server IP when deployed
  final String baseUrl = 'https://arohan-6.onrender.com';

  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'auth_role';
  static const String _usernameKey = 'auth_username';
  static const String _offlineSosQueueKey = 'offline_sos_queue';

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['access_token']);
      await prefs.setString(_roleKey, data['role'] ?? 'staff');
      await prefs.setString(_usernameKey, data['username'] ?? username);
      
      // TRIGGER CLOUD SYNC IN BACKGROUND (Non-blocking)
      syncCloudProfile();
      
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  Future<void> signup(String username, String password, {String role = 'staff'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'role': role}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Signup failed');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_usernameKey);
    await prefs.remove('guardian_numbers');
  }

  Future<void> syncCloudProfile() async {
    try {
      final userId = await getUserId();
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final prefs = await SharedPreferences.getInstance();
        
        final cloudPhones = data['guardian_numbers'] as List?;
        if (cloudPhones != null && cloudPhones.isNotEmpty) {
          await prefs.setStringList('guardian_numbers', List<String>.from(cloudPhones.map((p) => p.toString())));
        }

        if (data['full_name'] != null) await prefs.setString(_usernameKey, data['full_name']);
        print("Arohan Cloud Sync: Success for $userId");
      }
    } catch (e) {
      // Quiet fail — common when offline or Firestore disabled
      debugPrint("Cloud Profile Sync (Optional): Unavailable ($e)");
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── SOS ──────────────────────────────────────────────────────────────────

  Future<void> sendSos(SOSCreate sosData) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sos'),
        headers: headers,
        body: jsonEncode(sosData.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("SOS Sent Successfully!");
        await _syncOfflineSos();
      } else {
        throw Exception("Server rejected SOS: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error. Queuing SOS locally... Error: $e");
      await _queueSosOffline(sosData);
      throw Exception("You are offline. SOS queued.");
    }
  }

  Future<void> _queueSosOffline(SOSCreate sosData) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_offlineSosQueueKey) ?? [];
    queue.add(jsonEncode(sosData.toJson()));
    await prefs.setStringList(_offlineSosQueueKey, queue);
  }

  Future<void> _syncOfflineSos() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_offlineSosQueueKey) ?? [];
    if (queue.isEmpty) return;
    List<String> failed = [];
    for (String item in queue) {
      try {
        final headers = await _authHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/sos'),
          headers: headers,
          body: item,
        ).timeout(const Duration(seconds: 5));
        if (response.statusCode != 201 && response.statusCode != 200) {
          failed.add(item);
        }
      } catch (_) {
        failed.add(item);
      }
    }
    await prefs.setStringList(_offlineSosQueueKey, failed);
  }

  // ─── Incidents ────────────────────────────────────────────────────────────

  Future<bool> acknowledgeIncident(String incidentId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/incidents/$incidentId/acknowledge'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("ACK failed: $e");
      return false;
    }
  }

  Future<bool> escalateIncident(String incidentId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/alert/escalate'),
        headers: headers,
        body: jsonEncode({'incident_id': incidentId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Escalation failed: $e");
      return false;
    }
  }

  // ─── Photo Upload ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadIncidentPhoto({
    required File imageFile,
    required String incidentId,
    String description = '',
  }) async {
    final token = await getToken();
    final username = await getUsername() ?? 'guest';

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/photos/upload'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['incident_id'] = incidentId;
    request.fields['user_id'] = username;
    request.fields['description'] = description;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Photo upload failed: ${response.statusCode}');
    }
  }

  Future<void> simulateMultiSourceEvent(String source, String type, int floor) async {
    try {
      final headers = await _authHeaders();
      await http.post(
        Uri.parse('$baseUrl/sos'),
        headers: headers,
        body: jsonEncode({
          'user_id': '${source}_simulation',
          'emergency_type': type,
          'location': {'lat': 28.6139, 'long': 77.2090, 'floor': floor},
          'source': source,
        }),
      );
    } catch (e) {
      print("Simulation failed: $e");
    }
  }

  Future<void> processVisualTriage(String incidentId, List<String> imageUrls) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/triage/visual'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'incident_id': incidentId,
          'image_urls': imageUrls,
        }),
      );
      if (response.statusCode == 200) {
        print("Arohan Vision: AI Triage triggered for $incidentId");
      }
    } catch (e) {
      print("Arohan Vision Error: $e");
    }
  }
}
