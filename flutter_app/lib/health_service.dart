import 'package:flutter/material.dart'; // Για τη δημιουργία του UI
import 'package:health/health.dart';

class HealthService {
  static final health = Health();

  static Future<Map<String, dynamic>> fetchHealthData() async {
    List<HealthDataType> types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_SESSION,
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    ];

    // Αρχικές τιμές
    int steps = 0;
    double hrv = 0.0;
    double heartRate = 0.0;
    double sleepHours = 0.0;

    try {
      //Ζητάμε άδεια πρόσβασης στα δεδομένα υγείας
      await health.requestAuthorization(types);
      /*
      if (hasPermissions == false) {
        debugPrint("Ο χρήστης ΔΕΝ έδωσε άδεια πρόσβασης.");
        // Επιστρέφουμε ένα flag για να ξέρει η Home ότι δεν έχουμε άδεια
        return {'permissionsGranted': false}; 
      }
      */
      final endTime = DateTime.now();
      final startTime = endTime.subtract(const Duration(days: 1));
      
      // Ανάκτηση βημάτων
      try{steps = await health.getTotalStepsInInterval(startTime, endTime) ?? 0;
      }
      catch(e){
        debugPrint("Σφάλμα ανάκτησης βημάτων: $e");
      }

      // Ανάκτηση HRV
      try{
      final hrvData = await health.getHealthDataFromTypes(startTime: startTime, endTime: endTime, types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN]);
      if (hrvData.isNotEmpty) {
        double sum = 0.0;
        for (var data in hrvData) {
          sum += (data.value as NumericHealthValue).numericValue.toDouble();
        }
        hrv = sum / hrvData.length;
      }}
      catch(e){
        debugPrint("Σφάλμα ανάκτησης HRV: $e");
      }

      // Ανάκτηση HR
      try{
      final hrData = await health.getHealthDataFromTypes(startTime: startTime, endTime: endTime, types: [HealthDataType.HEART_RATE]);
      if (hrData.isNotEmpty) {
        double sum = 0.0;
        for (var data in hrData) {
          sum += (data.value as NumericHealthValue).numericValue.toDouble();
        }
        heartRate = sum / hrData.length;
      }}
      catch(e){
        debugPrint("Σφάλμα ανάκτησης HR ή HRV: $e");
      }

      // Ανάκτηση δεδομένων ύπνου
      try{
      final sleepData = await health.getHealthDataFromTypes(startTime: startTime, endTime: endTime, types: [HealthDataType.SLEEP_SESSION]);
      if (sleepData.isNotEmpty) {
        double totalMinutes = 0.0;
        for (var data in sleepData) {
          totalMinutes += (data.value as NumericHealthValue).numericValue.toDouble();
        }
        sleepHours = totalMinutes / 60.0;
      }}    catch(e){
        debugPrint("Σφάλμα ανάκτησης ύπνου: $e");
      }
    } catch (e) {
      debugPrint("Σφάλμα κατά την ανάκτηση δεδομένων υγείας: $e");
    }
    // Επιστρέφουμε όλα τα δεδομένα συγκεντρωμένα
    return {
      'permissionsGranted': true,
      'steps': steps,
      'hrv': hrv,
      'heartRate': heartRate,
      'sleepHours': sleepHours,
    };
  }
}