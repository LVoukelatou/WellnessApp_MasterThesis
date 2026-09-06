import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    final goals = (userDoc.data()?['goals'] as Map<String, dynamic>?) ?? {};

    return await _apiService.predictStress(
      isMorning: isMorning,
      vibeCheck1: v1,
      vibeCheck2: v2,
      vibeCheck3: v3,
      steps: steps,
      sleepHours: sleepHours,
      heartRate: heartRate,
      hrv: hrv,
      stepsTarget: (goals['steps'] as num?)?.toDouble() ?? 10000,
      sleepTarget: (goals['sleep_hours'] as num?)?.toDouble() ?? 8.0,
      hrTarget: (goals['heart_rate'] as num?)?.toDouble() ?? 70,
      hrvTarget: (goals['hrv'] as num?)?.toDouble() ?? 50,
    );
  }
}
