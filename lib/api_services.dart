import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //final String apiUrl = 'http://10.0.2.2:5000/analyze_stress'; // μόνο για test στον emulator
  //final String apiUrl = 'http://192.168.2.9:5000/analyze_stress'; //σπιτι
  final String apiUrl = 'http://localhost:5000/analyze_stress'; // για test στον υπολογιστή
  Future<Map<String, dynamic>> predictStress({
    required bool isMorning,
    required int vibeCheck1,
    required int vibeCheck2,
    required int vibeCheck3,
    int? steps,
    double? sleepHours,
    double? heartRate,
    double? hrv, 
    required double stepsTarget, 
    required double sleepTarget, 
    required double hrTarget, 
    required double hrvTarget
    }) //σε {} για να μπορούμε να περάσουμε τα ορίσματα με όποια σειρά θέλουμε
    async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "is_morning": isMorning,
          "survey": {
            "v1": vibeCheck1,
            "v2": vibeCheck2,
            "v3": vibeCheck3
          },
          "health": {
            "steps": steps,
            "sleep_hours": sleepHours,
            "heart_rate": heartRate,
            "hrv": hrv
          },
          "steps_goal": stepsTarget,
          "sleep_goal": sleepTarget,
          "hr_goal": hrTarget,
          "hrv_goal": hrvTarget,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Αποτυχία ανάλυσης στρες. Κωδικός κατάστασης: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Σφάλμα σύνδεσης με το API: $e');
    }
  }
}