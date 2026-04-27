import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _username = "Loading...";
  String _email = "No email set";
  List<String> _guardianPhones = List.generate(5, (_) => "No Number Set");

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await ApiService().getUsername();
    final String? userId = await ApiService().getUserId();
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Initial load from local cache for instant UI
    final localPhones = prefs.getStringList('guardian_numbers');
    if (localPhones != null && localPhones.isNotEmpty) {
      setState(() {
        _guardianPhones = List<String>.from(localPhones);
        while (_guardianPhones.length < 5) _guardianPhones.add("No Number Set");
      });
    }

    if (mounted) {
      setState(() { _username = name ?? "Guest User"; });
    }

    // 2. Fetch latest from Cloud and override/sync
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final cloudPhones = data['guardian_numbers'] as List?;
          
          if (cloudPhones != null && cloudPhones.isNotEmpty) {
            List<String> synchronized = List<String>.from(cloudPhones.map((p) => p.toString()));
            while (synchronized.length < 5) synchronized.add("No Number Set");
            
            setState(() {
              _username = data['full_name'] ?? _username;
              _email = data['email'] ?? "No email set";
              _guardianPhones = synchronized;
            });

            // Keep local cache updated with cloud
            await prefs.setStringList('guardian_numbers', synchronized);
          }
        }
      } catch (e) {
        print("Cloud Sync Error (Loading): $e");
      }
    }
  }

  void _showPersonalInfoSheet() {
    TextEditingController nameController = TextEditingController(text: _username);
    TextEditingController emailController = TextEditingController(text: _email == "No email set" ? "" : _email);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1421),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("PERSONAL INFORMATION", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 30),
              _editField("Full Name", nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _editField("Email / Contact", emailController, Icons.email_outlined),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final String? userId = await ApiService().getUserId();
                    if (userId != null) {
                      await FirebaseFirestore.instance.collection('users').doc(userId).set({
                        'full_name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                      }, SetOptions(merge: true));
                    }
                    setState(() {
                      _username = nameController.text.trim();
                      _email = emailController.text.trim();
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated in Cloud!"), backgroundColor: Colors.green));
                  },
                  child: const Text("UPDATE PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.5), size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Future<void> _editGuardianNumber(int index) async {
    String current = _guardianPhones[index];
    TextEditingController controller = TextEditingController(text: current != "No Number Set" ? current : "");
    String? newNumber = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131B2A),
        title: Text("Edit Sentinel ${index + 1}", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "+91 00000 00000",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newNumber != null) {
      final String? userId = await ApiService().getUserId();
      final prefs = await SharedPreferences.getInstance();
      
      // Update local list
      List<String> updatedList = List<String>.from(_guardianPhones);
      updatedList[index] = newNumber.isEmpty ? "No Number Set" : newNumber;
      
      setState(() { _guardianPhones = updatedList; });

      // 1. Save to Local Memory (Instant)
      await prefs.setStringList('guardian_numbers', updatedList);

      // 2. Save to Cloud (Permanent)
      if (userId != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'guardian_numbers': updatedList,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print("Cloud Sync Success: Numbers locked in for $userId");
        } catch (e) {
          print("Cloud Save Error: $e");
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sentinel numbers locked & saved!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Avatar Section
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 3),
                image: DecorationImage(image: NetworkImage("https://ui-avatars.com/api/?name=${_username}&background=0D8ABC&color=fff&size=128&format=png"), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(_username.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            _menuButton("Personal Information", Icons.person_outline, _showPersonalInfoSheet),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
              child: Column(
                children: [
                  _menuButton("Emergency SOS Guardians", Icons.shield_outlined, () {}),
                  ...List.generate(5, (index) => _guardianTile(index)),
                ],
              ),
            ),

            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                await ApiService().logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _guardianTile(int index) {
    return ListTile(
      leading: Icon(Icons.security, color: index == 0 ? Colors.redAccent : Colors.white24, size: 20),
      title: Text("SENTINEL ${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(_guardianPhones[index], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), onPressed: () => _editGuardianNumber(index)),
    );
  }

  Widget _menuButton(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.white24),
    );
  }
}
