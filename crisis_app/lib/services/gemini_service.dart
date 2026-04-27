// MOCKED Gemini Service for Demo (Zero Dependency)
class GeminiService {
  Future<Map<String, dynamic>> analyzeIncident(String description) async {
    // Simulate AI thinking delay
    await Future.delayed(Duration(seconds: 1));
    
    try {
      print("AI ANALYZING: $description");
      
      if (description.toLowerCase().contains("fire")) {
        return {
          "type": "fire",
          "severity": 9,
          "action": "CRITICAL: Deploy fire suppressors and evacuate Floor 3."
        };
      } else if (description.toLowerCase().contains("medical")) {
        return {
          "type": "medical",
          "severity": 7,
          "action": "TACTICAL: Dispatch paramedics to Zone B via North Entrance."
        };
      }
      
      return {
        "type": "emergency",
        "severity": 8,
        "action": "ALARM: Initiate standard evacuation protocols immediately."
      };
    } catch (e) {
      print("Gemini Mock Error: $e");
      return {
        "type": "unknown",
        "severity": 8,
        "action": "CRITICAL: Evacuate the area immediately."
      };
    }
  }
}
