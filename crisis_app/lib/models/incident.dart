import 'location.dart';

class Incident {
  final String? id;
  final String type;
  final int severity;
  final Location location;
  final String source;
  final String status;
  final String? assignedTo;
  final String? timestamp;
  final bool escalated;
  final String? aiAnalysis;
  
  // NEW: Media Witness Fields
  final List<String>? evidenceImages;
  final String? evidenceAudio;
  final bool captureComplete;

  Incident({
    this.id,
    required this.type,
    required this.severity,
    required this.location,
    required this.source,
    required this.status,
    this.assignedTo,
    this.timestamp,
    this.escalated = false,
    this.aiAnalysis,
    this.evidenceImages,
    this.evidenceAudio,
    this.captureComplete = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'severity': severity,
      'location': location.toJson(),
      'source': source,
      'status': status,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (timestamp != null) 'timestamp': timestamp,
      'escalated': escalated,
      if (aiAnalysis != null) 'ai_analysis': aiAnalysis,
      if (evidenceImages != null) 'evidence_images': evidenceImages,
      if (evidenceAudio != null) 'evidence_audio': evidenceAudio,
      'capture_complete': captureComplete,
    };
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    final rawSeverity = json['severity'];
    final int parsedSeverity = rawSeverity is int
        ? rawSeverity
        : int.tryParse(rawSeverity?.toString() ?? '5') ?? 5;

    Location parsedLocation;
    try {
      final locRaw = json['location'];
      if (locRaw is Map) {
        parsedLocation = Location.fromJson(Map<String, dynamic>.from(locRaw));
      } else {
        parsedLocation = Location(lat: 0, long: 0, floor: 0);
      }
    } catch (_) {
      parsedLocation = Location(lat: 0, long: 0, floor: 0);
    }

    // Handle evidence_images if it's a dynamic list
    List<String>? images;
    if (json['evidence_images'] is List) {
      images = List<String>.from(json['evidence_images']);
    }

    return Incident(
      id: json['id']?.toString(),
      type: json['type']?.toString() ?? 'unknown',
      severity: parsedSeverity,
      location: parsedLocation,
      source: json['source']?.toString() ?? 'unknown',
      status: json['status']?.toString() ?? 'active',
      assignedTo: json['assigned_to']?.toString(),
      timestamp: json['timestamp']?.toString(),
      escalated: json['escalated'] == true,
      aiAnalysis: json['ai_analysis']?.toString(),
      evidenceImages: images,
      evidenceAudio: json['evidence_audio']?.toString(),
      captureComplete: json['capture_complete'] == true,
    );
  }
}

class SOSCreate {
  final String userId;
  final Location location;
  final String emergencyType;
  final dynamic phone;

  SOSCreate({
    required this.userId,
    required this.location,
    required this.emergencyType,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'location': location.toJson(),
      'emergency_type': emergencyType,
      if (phone != null) 'phone': phone,
    };
  }
}
