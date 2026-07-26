import 'package:flutter/material.dart'; // Για τη δημιουργία του UI
import 'package:health/health.dart';

class HealthService {
  static final health = Health();

  static Future<Map<String, dynamic>> fetchHealthData() async {
    List<HealthDataType> types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_SESSION,
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    ];

    // Αρχικές τιμές
    int steps = 0;
    double hrv = 0.0;
    double heartRate = 0.0;
    double sleepHours = 0.0;

    try {
      //Ανάκτηση δεδομένων υγείας από το Health Connect
      await health.configure(); 
      final status = await health.getHealthConnectSdkStatus();
debugPrint("STATUS = $status");

final granted = await health.requestAuthorization(types);
debugPrint("GRANTED = $granted");

final has = await health.hasPermissions(types);
debugPrint("HAS = $has");
/*
      final status = await health.getHealthConnectSdkStatus(); // Έλεγχος αν το Health Connect είναι διαθέσιμο
      debugPrint("Health Connect status: $status"); 
      bool granted = await health.requestAuthorization(types); // Αίτηση για άδειες πρόσβασης στα δεδομένα υγείας
      debugPrint("Permissions granted: $granted");
*/     
      if (!granted) {
        debugPrint("Ο χρήστης δεν έδωσε άδειες - διακοπή");
        return {
          'permissionsGranted': false,
          'steps': 0, 'hrv': 0.0, 'heartRate': 0.0, 'sleepHours': 0.0,
        };
      }

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
      final hrvData = await health.getHealthDataFromTypes(startTime: startTime, endTime: endTime, types: [HealthDataType.HEART_RATE_VARIABILITY_RMSSD]);
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