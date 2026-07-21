/*
import 'package:flutter/material.dart'; // Για τα widgets και το UI
import 'dart:ui' as ui; // Για τα χρώματα και το UI
import 'package:cloud_firestore/cloud_firestore.dart'; // Για την αλληλεπίδραση με το Cloud Firestore
import 'package:health/health.dart'; // Για την αλληλεπίδραση με το Health Connect και την ανάκτηση δεδομένων υγείας
import 'package:http/http.dart'
    as http; // Για την αποστολή δεδομένων στο Flask API
import 'dart:convert'; // Για την κωδικοποίηση και αποκωδικοποίηση JSON
import "api_services.dart"; // Για την αλληλεπίδραση με το Flask API

// Το HomeScreen είναι ένα StatefulWidget που θα εμφανίζει τα δεδομένα υγείας και θα επιτρέπει την αλληλεπίδραση με τον χρήστη
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Η κατάσταση του HomeScreen, όπου θα διαχειριζόμαστε τις άδειες, τα δεδομένα υγείας και την εμφάνιση του UI
class _HomeScreenState extends State<HomeScreen> {
  List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN, //απαιτεί wearable συσκευή
  ];

  // Μεταβλητές για την κατάσταση των αδειών και τα πραγματικά βήματα που θα ανακτήσουμε από το Health Connect
  bool permissionsGranted = false;
  int actualSteps = 0;
  double actualHRV = 0.0;
  double actualHeartRate = 0.0;
  double actualSleepHours = 0.0;
  // Μεταβλητές για την πρόβλεψη του επιπέδου στρες από το Flask API
  bool isLoading = false;
  double backendPredictedStress =
      0.0; // Η πρόβλεψη του επιπέδου στρες που λαμβάνουμε από το Flask API
  String backendInsight =
      ''; // Η ερμηνεία της πρόβλεψης που λαμβάνουμε από το Flask API

  int vibeCheck1 =
      2; // Αποθηκεύει την απάντηση στην ερώτηση 1 του ερωτηματολογίου, προεπιλεγμένη τιμή 2 (μέτριο)
  int vibeCheck2 =
      2; // ερώτηση 2 του ερωτηματολογίου, προεπιλεγμένη τιμή 2 (μέτριο)
  int vibeCheck3 =
      2; // ερώτηση 3 του ερωτηματολογίου, προεπιλεγμένη τιμή 2 (μέτριο)

  bool isMorning =
      true; // Αποθηκεύει αν είναι πρωί ή απόγευμα για να προσαρμόζει την ερώτηση του ερωτηματολογίου ανάλογα με την ώρα της ημέρας

  // Οι λίστες με τα ονόματα των ημερών και των μηνών για την εμφάνιση της τρέχουσας ημερομηνίας με ελληνικούς χαρακτήρες
  final List<String> days = [
    'Δευτέρα',
    'Τρίτη',
    'Τετάρτη',
    'Πέμπτη',
    'Παρασκευή',
    'Σάββατο',
    'Κυριακή',
  ];
  final List<String> months = [
    'Ιανουαρίου',
    'Φεβρουαρίου',
    'Μαρτίου',
    'Απριλίου',
    'Μαΐου',
    'Ιουνίου',
    'Ιουλίου',
    'Αυγούστου',
    'Σεπτεμβρίου',
    'Οκτωβρίου',
    'Νοεμβρίου',
    'Δεκεμβρίου',
  ];
  String get dayName => days[DateTime.now().weekday - 1];
  String get monthName => months[DateTime.now().month - 1];
  String get formattedDate => '$dayName, ${DateTime.now().day} $monthName';
  @override
  // Η μέθοδος initState καλείται όταν το widget δημιουργείται για πρώτη φορά. Εδώ ζητάμε τις άδειες για την πρόσβαση στα δεδομένα υγείας και ανακτούμε τα βήματα.
  void initState() {
    super.initState();
    final hour = DateTime.now()
        .hour; // Παίρνουμε την τρέχουσα ώρα για να καθορίσουμε αν είναι πρωί ή απόγευμα
    isMorning = hour < 14; // Αν η ώρα είναι πριν τις 14:00 είναι πρωί
    requestHealthPermissions();
  }

  Future<void> requestHealthPermissions() async {
    final health = Health();
    try {
      await health.requestAuthorization(types);
      final endTime = DateTime.now(); // Τρέχουσα ώρα
      final startTime = endTime.subtract(
        const Duration(days: 1),
      ); // Από χθες μέχρι τώρα
      actualSteps =
          await health.getTotalStepsInInterval(startTime, endTime) ?? 0;

      try {
        final hrv = await health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: endTime,
          types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        );
        if (hrv.isNotEmpty) {
          double sum = 0.0;
          for (var data in hrv) {
            sum += (data.value as NumericHealthValue).numericValue
                .toDouble(); // Προσθέτουμε την τιμή του HRV στη μεταβλητή sum, κάνοντας cast σε NumericHealthValue για να πάρουμε την αριθμητική τιμή του HRV
          }
          actualHRV = sum / hrv.length; // Υπολογίζουμε τον μέσο όρο του HRV
        } else {
          debugPrint("Δεν βρέθηκαν δεδομένα HRV για το συγκεκριμένο διάστημα.");
        }
      } catch (e) {
        debugPrint("Σφάλμα κατά την αίτηση άδειας για HRV: $e");
      }
      try {
        final heartRate = await health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: endTime,
          types: [HealthDataType.HEART_RATE],
        );
        if (heartRate.isNotEmpty) {
          double sum = 0.0;
          for (var data in heartRate) {
            sum += (data.value as NumericHealthValue).numericValue
                .toDouble(); // Προσθέτουμε την τιμή του καρδιακού ρυθμού στη μεταβλητή sum, κάνοντας cast σε NumericHealthValue για να πάρουμε την αριθμητική τιμή του καρδιακού ρυθμού
          }
          actualHeartRate =
              sum /
              heartRate
                  .length; // Υπολογίζουμε τον μέσο όρο του καρδιακού ρυθμού
        } else {
          debugPrint(
            "Δεν βρέθηκαν δεδομένα καρδιακού ρυθμού για το συγκεκριμένο διάστημα.",
          );
        }
      } catch (e) {
        debugPrint("Σφάλμα κατά την αίτηση άδειας για καρδιακό ρυθμό: $e");
      }

      try {
        final sleep = await health.getHealthDataFromTypes(
          startTime: startTime,
          endTime: endTime,
          types: [HealthDataType.SLEEP_SESSION],
        );
        if (sleep.isNotEmpty) {
          double totalSleepMinutes = 0.0;
          for (var data in sleep) {
            totalSleepMinutes += (data.value as NumericHealthValue).numericValue
                .toDouble(); // Προσθέτουμε την διάρκεια του ύπνου σε λεπτά στη μεταβλητή totalSleepMinutes, κάνοντας cast σε NumericHealthValue για να πάρουμε την αριθμητική τιμή της διάρκειας του ύπνου σε λεπτά
          }
          actualSleepHours =
              totalSleepMinutes / 60.0; // Μετατρέπουμε τα λεπτά σε ώρες
        } else {
          debugPrint("Δεν βρέθηκαν δεδομένα ύπνου.");
        }
      } catch (e) {
        debugPrint("Σφάλμα ύπνου: $e");
      }
    } catch (e) {
      debugPrint("Σφάλμα Health Connect: $e");
      setState(() {
        permissionsGranted = false;
      });
    }
    setState(() {
      permissionsGranted = true;
      actualSteps =
          actualSteps ??
          0; // Κανουμε null check για να αποφύγουμε σφάλματα αν δεν υπάρχουν δεδομένα βημάτων
    });
  }

  Future<void> predictStress() async {
    setState(() {
      isLoading =
          true; // Δείχνουμε οτι το σύστημα φορτώνει και περιμένουμε την απάντηση από το Flask API
    });

    try {
      final apiService =
          ApiService(); // Δημιουργούμε ένα αντικείμενο της κλάσης ApiService για να καλέσουμε τη μέθοδο predictStress
      final result = await apiService.predictStress(
        isMorning: isMorning,
        vibeCheck1: vibeCheck1,
        vibeCheck2: vibeCheck2,
        vibeCheck3: vibeCheck3,
        steps: actualSteps,
        sleepHours: actualSleepHours,
        heartRate: actualHeartRate,
      );
      // Ενημερώνουμε το state με τα αποτελέσματα που λάβαμε από το Flask API
      setState(() {
        backendPredictedStress =
            result['daily_stress_score'] ??
            0.0; // Αν δεν υπάρχει το κλειδί 'daily_stress_score' στο αποτέλεσμα, θέτουμε την τιμή σε 0.0
        backendInsight =
            result['insight_message'] ??
            ''; // Αν δεν υπάρχει το κλειδί 'insight_message' στο αποτέλεσμα, θέτουμε την τιμή σε κενό string
      });
    } catch (e) {
      debugPrint("Σφάλμα κατά την πρόβλεψη στρες: $e");
    } finally {
      setState(() {
        isLoading =
            false; // Σταματάμε να δείχνουμε οτι το σύστημα φορτώνει αφού λάβαμε την απάντηση από το Flask API
      });
    }
  }
  //Συνάρτηση που εμφανίζει ένα διάλογο με τις ερωτήσεις του ερωτηματολογίου για το vibe check, ανάλογα με το αν είναι πρωί ή απόγευμα
  Future<void> _showVibeCheckDialog(bool isMorning) async {
    double v1 = 2.0; // Αποθηκεύει την απάντηση στην ερώτηση 1 του ερωτηματολογίου, προεπιλεγμένη τιμή 2 (μέτριο)
    double v2 = 2.0;
    double v3 = 2.0;

    await showDialog(
      context: context,
      barrierDismissible: false, // Αποτρέπει το κλείσιμο του διαλόγου με tap έξω από αυτόν
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              // Αλλάζει τον τίτλο ανάλογα με την ώρα
              title: Text(
                isMorning ? 'Πρωινό Check-in 🌅' : 'Απογευματινό Check-in 🌇',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ερώτηση 1 (Διάθεση)
                    Text(isMorning 
                        ? '1. Πώς νιώθεις ξεκινώντας τη μέρα σου;' 
                        : '1. Πώς νιώθεις τώρα που τελείωσε ο κύριος όγκος δουλειάς;'),
                    Slider(
                      value: v1, min: 1, max: 3, divisions: 2,
                      activeColor: Colors.blueAccent,
                      label: isMorning 
                          ? (v1 == 1 ? 'Χαλαρά' : (v1 == 2 ? 'Κάπως πιεσμένα' : 'Αγχωμένα'))
                          : (v1 == 1 ? 'Ανακουφισμένα' : (v1 == 2 ? 'Είμαι την τσίτα' : 'Είμαι πτώμα')),
                      onChanged: (value) => setState(() => v1 = value),
                    ),
                    const Divider(),

                    // Ερώτηση 2 (Φόρτος / Σωματική Ένταση)
                    Text(isMorning 
                        ? '2. Πόσο βαρύ είναι το σημερινό πρόγραμμα;' 
                        : '2. Νιώθεις σωματική ένταση (π.χ. αυχένα/μέση);'),
                    Slider(
                      value: v2, min: 1, max: 3, divisions: 2,
                      activeColor: Colors.orangeAccent,
                      label: isMorning 
                          ? (v2 == 1 ? 'Ελαφρύ' : (v2 == 2 ? 'Μέτριο' : 'Back-to-Back'))
                          : (v2 == 1 ? 'Καθόλου' : (v2 == 2 ? 'Λιγάκι' : 'Πονάω αρκετά')),
                      onChanged: (value) => setState(() => v2 = value),
                    ),
                    const Divider(),

                    // Ερώτηση 3 (Ενέργεια / Αποσύνδεση)
                    Text(isMorning 
                        ? '3. Πώς ξύπνησες;' 
                        : '3. Πόσο εύκολο σου είναι να αποσυνδεθείς τώρα;'),
                    Slider(
                      value: v3, min: 1, max: 3, divisions: 2,
                      activeColor: Colors.redAccent,
                      label: isMorning 
                          ? (v3 == 1 ? 'Γεμάτη/ος ενέργεια' : (v3 == 2 ? 'Θέλω καφέ' : 'Εξαντλημένη/ος'))
                          : (v3 == 1 ? 'Πολύ εύκολο' : (v3 == 2 ? 'Το παλεύω' : 'Αδύνατον')),
                      onChanged: (value) => setState(() => v3 = value),
                    ),
                  ],
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      setState(() {
                        vibeCheck1 = v1.toInt();
                        vibeCheck2 = v2.toInt();
                        vibeCheck3 = v3.toInt();
                      })
                    },
                    child: const Text('Αποθήκευση'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 201, 254, 201),
        appBar: AppBar(
          backgroundColor: const ui.Color.fromARGB(255, 15, 55, 17),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Καλωσήρθες, Λουκία!',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color.fromARGB(255, 188, 255, 192),
                ),
              ),
            ],
          ),
        ),

        body: RefreshIndicator(
          onRefresh: () async {
            await requestHealthPermissions(); // Επαναφόρτωση των δεδομένων υγείας όταν ο χρήστης κάνει pull-to-refresh
          },
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Επιτρέπει το pull-to-refresh ακόμα και όταν το περιεχόμενο δεν γεμίζει την οθόνη
            child: Column(
              children: [
                //stress card
                Card(
                  //color: stressColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Επίπεδο Στρες',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        Text(
                          backendPredictedStress.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: const Color.fromARGB(255, 201, 254, 201),
                  child: Column(
                    spacing: 10,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Card(
                            color: const ui.Color.fromARGB(255, 118, 195, 122),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Βήματα',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontFamily: 'Google Sans',
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 15, 55, 17),
                                    ),
                                  ),
                                  Icon(
                                    Icons.directions_walk_rounded,
                                    size: 40,
                                    color: const ui.Color.fromARGB(
                                      255,
                                      15,
                                      55,
                                      17,
                                    ),
                                  ),
                                  permissionsGranted
                                      ? Column(
                                          children: [
                                            Text(
                                              '$actualSteps',
                                              textAlign: TextAlign.start,
                                              style: const TextStyle(
                                                fontFamily: 'Google Sans',
                                                fontSize: 18,
                                                color: Color.fromARGB(
                                                  255,
                                                  15,
                                                  55,
                                                  17,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: () {
        // Εδώ καλούμε τη συνάρτηση που φτιάξαμε!
        _showVibeCheckDialog(isMorning);
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
)
      ),
    );
  }

  Future<void> sendTestDataToFirebase() async {
    try {
      // Στέλνουμε δεδομένα στο Cloud Firestore
      await FirebaseFirestore.instance
          .collection('users') // Συλλογή χρηστών
          .doc('test_user_123') // Το ID του (δοκιμαστικού) χρήστη
          .collection('daily_logs') // Υπο-συλλογή με τις καθημερινές μετρήσεις
          .doc('2026-03-21') // Ημερομηνία ως όνομα εγγράφου
          .set({
            'steps': 4500,
            'sleep_hours': 7.5,
            'avg_heart_rate': 78,
            'questionnaire_score': 8,
            'stress_predicted': 'Normal',
            'timestamp':
                FieldValue.serverTimestamp(), // Κρατάει την ακριβή ώρα του server
          });

      print("ΕΠΙΤΥΧΙΑ! Τα δεδομένα ανέβηκαν στο Firebase!");
    } catch (e) {
      print("Σφάλμα: $e");
    }
  }
}
*/