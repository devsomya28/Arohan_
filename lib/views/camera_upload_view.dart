import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

/// Camera/Photo Upload View
/// Can be opened from the Guest or Staff screen.
/// Takes a photo (or picks from gallery) and uploads it to the backend,
/// linked to the given [incidentId].
class CameraUploadView extends StatefulWidget {
  final String incidentId;
  final String? incidentType;

  const CameraUploadView({Key? key, required this.incidentId, this.incidentType}) : super(key: key);

  @override
  _CameraUploadViewState createState() => _CameraUploadViewState();
}

class _CameraUploadViewState extends State<CameraUploadView> {
  File? _imageFile;
  bool _isUploading = false;
  bool _uploaded = false;
  String _description = '';
  String _statusMessage = '';
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,   // Compress to save bandwidth
        maxWidth: 1280,
        maxHeight: 960,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _uploaded = false;
          _statusMessage = '';
        });
      }
    } catch (e) {
      _showMessage("Could not access camera/gallery: $e", isError: true);
    }
  }

  Future<void> _uploadPhoto() async {
    if (_imageFile == null) {
      _showMessage("Please take or select a photo first.", isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading...';
    });

    try {
      final result = await _api.uploadIncidentPhoto(
        imageFile: _imageFile!,
        incidentId: widget.incidentId,
        description: _description.isNotEmpty ? _description : 'Photo from field',
      );

      setState(() {
        _uploaded = true;
        _statusMessage = 'Photo uploaded successfully! Photo ID: ${result['photo_id']}';
      });

      // Notify parent and pop after short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _statusMessage = '';
      });
      _showMessage("Upload failed: ${e.toString().replaceAll('Exception: ', '')}", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PHOTO EVIDENCE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text("Incident #${widget.incidentId.length > 8 ? widget.incidentId.substring(0, 8) : widget.incidentId}",
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident type badge
            if (widget.incidentType != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Text(
                  widget.incidentType!.toUpperCase(),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 24),

            // Photo preview
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imageFile != null ? const Color(0xFF6366F1) : Colors.white10,
                    width: _imageFile != null ? 2 : 1,
                  ),
                ),
                child: _imageFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Color(0xFF6366F1), size: 56),
                          SizedBox(height: 16),
                          Text("TAP TO TAKE PHOTO",
                              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          SizedBox(height: 8),
                          Text("Photo will be linked to this incident",
                              style: TextStyle(color: Colors.white24, fontSize: 10)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Source buttons
            Row(
              children: [
                Expanded(
                  child: _sourceBtn("CAMERA", Icons.camera_alt, () => _pickImage(ImageSource.camera)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceBtn("GALLERY", Icons.photo_library, () => _pickImage(ImageSource.gallery)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description field
            TextField(
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Describe what this photo shows (optional)...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              onChanged: (v) => _description = v,
            ),

            const SizedBox(height: 24),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _uploaded ? Colors.green.withOpacity(0.1) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _uploaded ? Colors.green : Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(_uploaded ? Icons.check_circle : Icons.info_outline,
                        color: _uploaded ? Colors.green : Colors.indigoAccent, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_statusMessage, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _uploaded ? Colors.green : const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_isUploading || _uploaded) ? null : _uploadPhoto,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _uploaded ? "✓ UPLOADED" : "UPLOAD TO INCIDENT",
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
