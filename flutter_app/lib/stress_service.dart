import 'api_services.dart';

class StressService {
  final ApiService _apiService = ApiService();

  // Μέθοδος που καλεί το ApiService για να πάρει την πρόβλεψη στρες
  Future<Map<String, dynamic>> getStressPrediction({
    required bool isMorning,
    required int v1,
    required int v2,
    required int v3,
    required int steps,
    required double sleepHours,
    required double heartRate,
    required double hrv,
  }) async {
    return await _apiService.predictStress(
      isMorning: isMorning,
      vibeCheck1: v1,
      vibeCheck2: v2,
      vibeCheck3: v3,
      steps: steps,
      sleepHours: sleepHours,
      heartRate: heartRate,
      hrv: hrv,
    );
  }
}