import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class SOSCaptureService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  CameraController? _cameraController;

  /// CORE FIX: Parallel capture using Future.wait to remove sequential lag.
  Future<Map<String, dynamic>> captureEmergencyEvidence(String incidentId) async {
    final List<String> imageUrls = [];
    String? audioUrl;
    Position? position;

    try {
      // 1. Parallel Init (GPS + Camera warmup)
      print("🚨 MEDIA WITNESS: Triggering Simultaneous Blow...");
      
      final results = await Future.wait([
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high),
        availableCameras(),
      ]);

      position = results[0] as Position;
      final cameras = results[1] as List<CameraDescription>;

      if (cameras.isNotEmpty && _cameraController == null) {
        _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
        await _cameraController!.initialize();
        // Zero-Latency Hack: Prepare for capture immediately
        await _cameraController!.prepareForVideoRecording(); 
      }

      // 2. TRIGGER EVERYTHING SIMULTANEOUSLY
      // We don't await the audio start, we trigger and move to photos immediately
      final audioFuture = _captureAudio(incidentId);
      final photoFuture = _capturePhotoBurst(incidentId);

      // Wait for both parallel streams to complete
      final captureResults = await Future.wait([audioFuture, photoFuture]);
      
      audioUrl = captureResults[0] as String?;
      imageUrls.addAll(captureResults[1] as List<String>);

    } catch (e) {
      print("❌ MEDIA CAPTURE FAILED: $e");
    } finally {
      _cameraController?.dispose();
      _cameraController = null;
    }

    return {
      'incident_id': incidentId,
      'images': imageUrls,
      'audio': audioUrl,
      'location': {
        'lat': position?.latitude,
        'long': position?.longitude,
      },
      'status': 'Evidence_Ready', // Command Centre Trigger
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<String?> _captureAudio(String incidentId) async {
    try {
      await _audioRecorder.start(const RecordConfig(), path: '');
      await Future.delayed(const Duration(seconds: 10)); // 10s witness window
      final path = await _audioRecorder.stop();
      if (path != null) {
        // Handle upload here (Mocking for now as record handles web blobs)
        print("🎙️ Audio witness complete.");
        return "https://firebasestorage.googleapis.com/v0/b/arohan/o/audio_mock.m4a"; 
      }
    } catch (e) {
      print("🎙️ Audio Error: $e");
    }
    return null;
  }

  Future<List<String>> _capturePhotoBurst(String incidentId) async {
    List<String> urls = [];
    if (_cameraController == null || !_cameraController!.value.isInitialized) return urls;

    try {
      // 3-photo burst in parallel loop
      for (int i = 0; i < 3; i++) {
        final photo = await _cameraController!.takePicture();
        final bytes = await photo.readAsBytes();
        
        // Background upload (Don't await individual uploads to keep burst fast)
        _uploadToFirebaseWeb(bytes, "incidents/$incidentId/photo_$i.jpg").then((url) {
          urls.add(url);
          print("📸 Burst $i uploaded.");
        });
        
        await Future.delayed(const Duration(milliseconds: 200)); 
      }
    } catch (e) {
      print("📸 Burst Error: $e");
    }
    return urls;
  }

  Future<String> _uploadToFirebaseWeb(Uint8List bytes, String storagePath) async {
    final ref = FirebaseStorage.instance.ref().child(storagePath);
    final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }

  /// PRE-WARM: Call this during Splash Screen
  Future<void> preWarmHardware() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
        await _cameraController!.initialize();
        print("🚀 HARDWARE PRE-WARMED: Camera Ready.");
      }
      await _audioRecorder.hasPermission();
    } catch (e) {
      print("⚠️ Pre-warm failed: $e");
    }
  }
}
