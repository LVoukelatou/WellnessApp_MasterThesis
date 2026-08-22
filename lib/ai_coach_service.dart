import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCoachService {
  //final String baseUrl = 'http://192.168.2.9:5000'; //σπιτι
  final String baseUrl = 'http://localhost:5000'; // για test στον υπολογιστή
  Future<String> sendMessage(String message, List<Map<String, String>> history) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai_coach'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'history': history}),
      );
      
      // Έλεγχος της απάντησης από τον server
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Δεν έλαβα απάντηση.';
      } else {
        throw Exception('Σφάλμα server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Σφάλμα σύνδεσης: $e');
    }
  }
}