import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffSkill { fire, medical, security, structural }

class StaffMember {
  final String id;
  final String name;
  final List<StaffSkill> skillsets;
  final String status; // 'available', 'busy', 'offline'
  final GeoPoint location;
  final DateTime lastSeen;

  StaffMember({
    required this.id,
    required this.name,
    required this.skillsets,
    required this.status,
    required this.location,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'skillsets': skillsets.map((s) => s.toString().split('.').last).toList(),
    'status': status,
    'location': location,
    'last_seen': lastSeen,
  };

  factory StaffMember.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return StaffMember(
      id: doc.id,
      name: data['name'] ?? '',
      skillsets: (data['skillsets'] as List ?? [])
          .map((s) => StaffSkill.values.firstWhere((e) => e.toString().contains(s)))
          .toList(),
      status: data['status'] ?? 'offline',
      location: data['location'] as GeoPoint,
      lastSeen: (data['last_seen'] as Timestamp).toDate(),
    );
  }
}
